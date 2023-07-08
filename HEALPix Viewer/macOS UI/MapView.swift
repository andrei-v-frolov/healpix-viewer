//
//  MapView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import MetalKit
import CFitsIO

// MARK: SwiftUI wrapper for ProjectedView
struct MapView: NSViewRepresentable {
    @Binding var map: Map?
    
    @Binding var projection: Projection
    @Binding var viewpoint: Viewpoint
    @Binding var magnification: Double
    @Binding var background: Color
    @Binding var light: Light
    @Binding var cursor: Cursor
    
    @AppStorage(animateKey) var animate: Bool = true
    @Binding var mapview: ProjectedView?
    @Binding var iskey: Bool
    
    typealias NSViewType = ProjectedView
    var view = ProjectedView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        DispatchQueue.main.async {
            view.mapview = self; view.window?.delegate = view
            mapview = view; iskey = view.window?.isKeyWindow == true
        }
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        let radian = Double.pi/180.0
        let rotation = ang2rot(viewpoint.lat*radian, viewpoint.lon*radian, -viewpoint.az*radian), w = rot2gen(rotation)
        let lightsrc = float4(ang2vec((90.0-light.lat)*radian, light.lon*radian), Float(light.amt/100.0))
        
        view.map = map
        view.projection = projection
        view.magnification = magnification
        
        if (animate) { view.target = w } else {
            view.w = w; view.omega = float3(0.0)
            view.rotation = rotation
        }
        
        view.background = background.components
        view.lightsource = lightsrc
        
        view.draw()
    }
}

// MARK: Metal renderer for projected maps
class ProjectedView: MTKView, NSWindowDelegate {
    // MARK: map
    var map: Map? = nil
    
    // MARK: SwiftUI MapView
    var mapview: MapView? = nil
    
    // MARK: compute pipeline
    static let inflight = 3; private var index = 0
    private var semaphore = DispatchSemaphore(value: inflight)
    private var buffers = [[MTLBuffer]]()
    
    // MARK: projection shaders
    let shaders: [Projection: (grid: MetalKernel, data: MetalKernel)] = [
        .mollweide:     (MetalKernel(kernel: "mollweide_grid"),     MetalKernel(kernel: "mollweide_data")),
        .hammer:        (MetalKernel(kernel: "hammer_grid"),        MetalKernel(kernel: "hammer_data")),
        .lambert:       (MetalKernel(kernel: "lambert_grid"),       MetalKernel(kernel: "lambert_data")),
        .isometric:     (MetalKernel(kernel: "isometric_grid"),     MetalKernel(kernel: "isometric_data")),
        .gnomonic:      (MetalKernel(kernel: "gnomonic_grid"),      MetalKernel(kernel: "gnomonic_data")),
        .mercator:      (MetalKernel(kernel: "mercator_grid"),      MetalKernel(kernel: "mercator_data")),
        .cylindrical:   (MetalKernel(kernel: "cylindrical_grid"),   MetalKernel(kernel: "cylindrical_data")),
        .werner:        (MetalKernel(kernel: "werner_grid"),        MetalKernel(kernel: "werner_data"))
    ]
    
    // MARK: state variables
    var projection = Projection.defaultValue
    var magnification = 0.0
    var padding = 0.1
    
    // MARK: global preferences
    var animate: Bool { UserDefaults.standard.bool(forKey: animateKey) }
    var inside: Bool { UserDefaults.standard.bool(forKey: viewFromInsideKey) }
    var lighting: Bool { UserDefaults.standard.bool(forKey: lightingKey) }
    var cursor: Bool { UserDefaults.standard.bool(forKey: cursorKey) }
    
    // MARK: affine tranform mapping screen to projection plane
    func transform(width: Double? = nil, height: Double? = nil, magnification: Double? = nil, padding: Double? = nil, anchor: Anchor = .c, flipx: Bool? = nil, flipy: Bool = true, shiftx: Double = 0.0, shifty: Double = 0.0) -> float3x2 {
        let flipx = flipx ?? inside
        let (x,y) = projection.extent, signx = flipx ? -1.0 : 1.0, signy = flipy ? -1.0 : 1.0
        let w = width ?? drawableSize.width, h = height ?? drawableSize.height
        let m = magnification ?? self.magnification, p = padding ?? self.padding
        let s = 2.0 * (1.0+p) * max(x/w, y/h)/exp2(m), x0 = -s*w/2, y0 = -s*h/2
        let dx = signx*(x0 + anchor.halign*(x0+x) - s*shiftx)
        let dy = signy*y0  - anchor.valign*(y0+y) - s*shifty
        
        return simd.float3x2(float2(Float(flipx ? -s : s), 0.0), float2(0.0, Float(flipy ? -s : s)), float2(Float(dx), Float(dy)))
    }
    
    // MARK: antialiasing LOD
    func lod(_ nside: Int, transform: float3x2? = nil) -> Int {
        let t = transform ?? self.transform(), det = t[0,0]*t[1,1] - t[0,1]*t[1,0]
        let scale = sqrt(abs(det)), lod = Int(log2(scale*sqrt(2.0)*Float(nside))+0.5)
        
        switch AntiAliasing.value {
            case .none: return 0
            case .less: return max(0,lod-1)
            case .more: return max(0,lod+1)
        }
    }
    
    // MARK: arguments to shader
    var rotation = matrix_identity_float3x3
    var background = float4(0.0)
    var lightsource = float4(0.0)
    
    // if lighting effects are enabled, pass lighting to the shader
    var light: float4 {
        let flip = inside ? float4(1,-1,1,1) : float4(1)
        return lighting ? flip*lightsource : float4(0.0)
    }
    
    // MARK: solid body dynamics
    var w = float3.zero
    var omega = float3.zero
    var target = float3.zero { didSet { w = unwind(w, target: target) } }
    
    private let gamma: Float = 8.0
    private let kappa: Float = 16.0
    
    func step2(_ dt: Double) {
        w += omega * Float(dt/2.0)
        omega -= (gamma*omega + kappa*(w-target)) * Float(dt)
        w += omega * Float(dt/2.0)
    }
    
    func step6(_ dt: Double, steps n: Int = 1) {
        let dt = dt/Double(n), w: [Double] = [
             1.31518632068391121888424972823886251,
            -1.17767998417887100694641568096431573,
             0.235573213359358133684793182978534602,
             0.784513610477557263819497633866349876
        ]
        
        for _ in 0..<n { for i in -3...3 { step2(w[abs(i)]*dt) } }
    }
    
    // MARK: timing between the frames
    private var lastframe: CFTimeInterval = 0.0
    var dt: CFTimeInterval {
        let last = lastframe, now = CACurrentMediaTime(); lastframe = now
        return min(now-last, 5.0/Double(preferredFramesPerSecond))
    }
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        self.device = metal.device
        
        // initialize compute pipeline buffers
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        
        for _ in 0..<Self.inflight {
            guard let transform = metal.device.makeBuffer(length: MemoryLayout<float3x2>.size, options: options),
                  let rotation = metal.device.makeBuffer(length: MemoryLayout<float3x3>.size, options: options),
                  let bgcolor = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options),
                  let light = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options),
                  let lod = metal.device.makeBuffer(length: MemoryLayout<ushort>.size, options: options)
                  else { fatalError("Could not allocate parameter buffers in map view") }
            
            self.buffers.append([transform, rotation, bgcolor, light, lod])
        }
        
        // view options
        layer?.isOpaque = false
        framebufferOnly = false
        presentsWithTransaction = true
        
        // respond to mouse movement events
        let tracking: NSTrackingArea.Options = [.mouseMoved, .cursorUpdate, .activeInKeyWindow, .inVisibleRect]
        self.addTrackingArea(NSTrackingArea.init(rect: .zero, options: tracking, owner: self, userInfo: nil))
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
        // if spinning, advance the viewpoint towards target view
        if (animate) { step6(dt, steps: 3); rotation = gen2rot(w) }
        
        autoreleasepool {
            // check that we have a draw destination
            guard let command = metal.queue.makeCommandBuffer() else { return }
            guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
            
            // encode render command to drawable
            encode(command, to: drawable.texture)
            command.commit(); command.waitUntilScheduled()
            drawable.present()
        }
    }
    
    // MARK: encode render to command buffer
    func encode(_ command: MTLCommandBuffer, to texture: MTLTexture,
                transform: float3x2? = nil, rotation: float3x3? = nil,
                background: float4? = nil, lighting: float4? = nil) {
        guard let shader = shaders[projection] else { return }
        
        // wait for available buffer
        semaphore.wait()
        index = (index+1) % Self.inflight
        let buffers = self.buffers[index]
        
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform ?? self.transform(), as: float3x2.self)
        buffers[1].contents().storeBytes(of: rotation ?? self.rotation, as: float3x3.self)
        buffers[2].contents().storeBytes(of: background ?? self.background, as: float4.self)
        buffers[3].contents().storeBytes(of: lighting ?? self.light, as: float4.self)
        
        // render map if available
        if let map = map {
            let lod = lod(map.nside, transform: transform ?? self.transform())
            buffers[4].contents().storeBytes(of: ushort(min(lod,map.texture.mipmapLevelCount-1)), as: ushort.self)
            shader.data.encode(command: command, buffers: buffers, textures: [map.texture, texture])
        } else {
            shader.grid.encode(command: command, buffers: buffers, textures: [texture])
        }
        
        // signal completion
        command.addCompletedHandler { _ in self.semaphore.signal() }
    }
    
    // MARK: render image to off-screen texture
    func render(to texture: MTLTexture, anchor: Anchor = .c, shift: (x: Double, y: Double) = (0,0), magnification: Double? = nil, padding: Double? = nil, background: Color? = nil) {
        let rotation = animate ? gen2rot(target) : rotation
        let magnification = magnification ?? self.magnification, padding = padding ?? 0.0
        let transform = transform(width: Double(texture.width), height: Double(texture.height), magnification: magnification, padding: padding, anchor: anchor, flipy: false, shiftx: shift.x, shifty: shift.y)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        // encode render command
        encode(command, to: texture, transform: transform, rotation: rotation, background: background?.components)
        command.commit(); command.waitUntilCompleted()
    }
    
    // MARK: keep track of key status
    func windowDidBecomeKey(_ notification: Notification) { mapview?.iskey = true }
    func windowDidResignKey(_ notification: Notification) { mapview?.iskey = false }
    
    // MARK: spherical coordinates from event location
    func coordinates(_ event: NSEvent) -> (Double,Double)? {
        let location = convertToBacking(convert(event.locationInWindow, from: nil))
        let v = transform(flipy: isFlipped) * float3(Float(location.x), Float(location.y), 1)
        let u = rotation * projection.xyz(x: Double(v.x), y: Double(v.y))
        
        return (u != Projection.outOfBounds) ? vec2ang(u) : nil
    }
    
    // MARK: center map on the location of a right click
    override func rightMouseUp(with event: NSEvent) {
        guard let view = mapview, let (theta,phi) = coordinates(event) else { return }
        
        let radian = 180.0/Double.pi
        
        // geodesic rotation between two orientations
        if (!event.modifierFlags.contains(.option)) {
            let R = rotation, u = R[0], v = ang2vec(theta,phi)
            let w = cross(u,v), s = length(w), c = dot(u,v)
            let omega = (s != 0.0) ? atan2(s,c)/s * w : w
            
            let (_,_,psi) = rot2ang(gen2rot(omega)*R)
            view.viewpoint.az = -psi * radian
        }
        
        view.viewpoint.lat = (Double.pi/2.0 - theta) * radian
        view.viewpoint.lon = phi * radian
        view.viewpoint.orientation = .free
        view.cursor.hover = false
    }
    
    // MARK: cursor readout from projected map
    override func mouseMoved(with event: NSEvent) {
        guard let view = mapview, cursor else { return }
        guard let (theta,phi) = coordinates(event) else { view.cursor.hover = false; return }
        
        // cursor coordinates
        let radian = 180.0/Double.pi
        view.cursor.hover = true
        view.cursor.lat = (Double.pi/2.0 - theta) * radian
        view.cursor.lon = phi * radian
        
        // map pixel referenced
        var p = -1, v = 0.0; if let map = map {
            ang2pix_nest(map.nside, theta, phi, &p)
            v = Double(map.data[p])
        }
        
        view.cursor.pix = p
        view.cursor.val = v
    }
    
    // MARK: cursor is cross-hairs when readout is enabled
    override func cursorUpdate(with event: NSEvent) {
        if cursor { NSCursor.crosshair.set() }
    }
    
    // MARK: gesture support
    override func magnify(with event: NSEvent) {
        guard let view = mapview else { return }
        
        view.magnification += event.magnification
        if (view.magnification <  0.0) { view.magnification =  0.0 }
        if (view.magnification > 10.0) { view.magnification = 10.0 }
        
        view.cursor.hover = false
    }
    
    override func rotate(with event: NSEvent) {
        guard let view = mapview else { return }
        
        view.viewpoint.az += Double(inside ? -event.rotation : event.rotation)
        if (view.viewpoint.az >  180.0) { view.viewpoint.az -= 360.0 }
        if (view.viewpoint.az < -180.0) { view.viewpoint.az += 360.0 }
        
        view.viewpoint.orientation = .free
        view.cursor.hover = false
    }
    
    override func scrollWheel(with event: NSEvent) {
        guard animate else { return }
        
        let epsilon = Float(3.0e-2/exp2(magnification/2.0))
        let v = float3(0.0, Float(-event.deltaY), Float(inside ? event.deltaX : -event.deltaX))
        let R = rotation, w = rot2gen(gen2rot(epsilon*R*v) * R)
        omega += unwind(w, target: self.w) - self.w
        
        mapview?.cursor.hover = false
    }
}

// MARK: SO(3) group representations

// spherical coordinates to unit vector
func ang2vec(_ theta: Double, _ phi: Double) -> float3 {
    let z = cos(theta), r = sin(theta)
    
    return float3(Float(r*cos(phi)), Float(r*sin(phi)), Float(z))
}

// unit vector to spherical coordinates
func vec2ang(_ v: float3) -> (theta: Double, phi: Double) {
    let x = Double(v.x), y = Double(v.y), z = Double(v.z)
    
    return (atan2(sqrt(x*x+y*y),z), atan2(y,x))
}

// latitude, longitude and azimuth to rotation matrix
func ang2rot(_ theta: Double, _ phi: Double, _ psi: Double) -> float3x3 {
    let ct = Float(cos(theta)), st = Float(sin(theta))
    let cp = Float(cos(phi)), sp = Float(sin(phi))
    let ca = Float(cos(psi)), sa = Float(sin(psi))
    
    let xz = float3x3(float3(ct,0,st), float3(0,1,0), float3(-st,0,ct))
    let xy = float3x3(float3(cp,sp,0), float3(-sp,cp,0), float3(0,0,1))
    let yz = float3x3(float3(1,0,0), float3(0,ca,sa), float3(0,-sa,ca))
    
    return xy*xz*yz
}

// rotation matrix to latitude, longitude and azimuth
func rot2ang(_ R: float3x3) -> (theta: Double, phi: Double, psi: Double) {
    let theta = asin(Double(R[0,2]))
    let psi = atan2(Double(R[1,2]),Double(R[2,2]))
    let phi = atan2(Double(R[0,1]),Double(R[0,0]))
    
    return (theta,phi,psi)
}

// generator of rotation to rotation matrix
func gen2rot(_ w: float3) -> float3x3 {
    let theta = length(w); guard (theta > 0.0) else { return matrix_identity_float3x3 }
    let W = float3x3(float3(0.0,w.z,-w.y), float3(-w.z,0.0,w.x), float3(w.y,-w.x,0.0))
    let q = sin(theta)/theta, s = sin(theta/2.0)/theta, p = 2.0*s*s
    
    return matrix_identity_float3x3 + q*W + p*(W*W)
}

// rotation matrix to generator of rotation
func rot2gen(_ R: float3x3) -> float3 {
    let w = float3(R[1,2]-R[2,1], R[2,0]-R[0,2], R[0,1]-R[1,0])/2.0
    let s = length(w); guard (s > 0.0) else { return float3(0,0,0) }
    let trace = R[0,0]+R[1,1]+R[2,2], t = (trace-1.0)/2.0
    
    return atan2(s,t)/s * w
}

// shift generator of rotation by a multiple of 2*pi to be closest to target one
func unwind(_ w: float3, target t: float3) -> float3 {
    let l = length(w); guard l > 0.0 else { return w }
    let n = round(dot(t-w,w)/(2.0*Float.pi*l))
    return (1.0 + 2.0*Float.pi*n/l) * w
}
