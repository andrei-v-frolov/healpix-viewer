//
//  MapView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import MetalKit

// MARK: SwiftUI wrapper for ProjectedView
struct MapView: NSViewRepresentable {
    @Binding var map: Map?
    
    @Binding var projection: Projection
    @Binding var magnification: Double
    @Binding var spin: Bool
    
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var azimuth: Double
    
    @Binding var background: Color
    
    @Binding var lightingLat: Double
    @Binding var lightingLon: Double
    @Binding var lightingAmt: Double
    
    typealias NSViewType = ProjectedView
    var view = ProjectedView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        let radian = Double.pi/180.0
        let rotation = ang2rot(latitude*radian, longitude*radian, azimuth*radian), w = rot2gen(rotation)
        let lighting = ang2vec((90.0-lightingLat)*radian, lightingLon*radian)
        
        view.map = map
        view.projection = projection
        view.magnification = magnification
        view.spin = spin
        
        if (spin) { view.target = w } else {
            view.w = w; view.omega = float3(0.0)
            view.rotation = rotation
        }
        
        view.background = background.components
        view.lighting = float4(lighting, Float(lightingAmt/100.0))
        
        view.draw(view.bounds)
    }
}

// MARK: Metal renderer for projected maps
class ProjectedView: MTKView {
    // MARK: map
    var map: Map? = nil
    
    // MARK: compute pipeline
    var queue: MTLCommandQueue! = nil
    var buffers = [MTLBuffer]()
    
    // MARK: projection shaders
    let shaders: [Projection: (grid: MetalKernel, data: MetalKernel)] = [
        .mollweide: (MetalKernel(kernel: "mollweide_grid"), MetalKernel(kernel: "mollweide_data")),
        .gnomonic:  (MetalKernel(kernel: "gnomonic_grid"),  MetalKernel(kernel: "gnomonic_data")),
        .lambert:   (MetalKernel(kernel: "lambert_grid"),   MetalKernel(kernel: "lambert_data")),
        .isometric: (MetalKernel(kernel: "isometric_grid"), MetalKernel(kernel: "isometric_data")),
        .mercator:  (MetalKernel(kernel: "mercator_grid"),  MetalKernel(kernel: "mercator_data")),
        .werner:    (MetalKernel(kernel: "werner_grid"),    MetalKernel(kernel: "werner_data"))
    ]
    
    // MARK: state variables
    var projection = Projection.defaultValue
    var magnification = 0.0
    var padding = 0.1
    var spin = false
    
    // MARK: arguments to shader
    var transform: float3x2 {
        let (x,y) = projection.extent, w = drawableSize.width, h = drawableSize.height
        let s = 2.0 * (1.0+padding) * max(x/w, y/h)/exp2(magnification), dx = -s*w/2, dy = s*h/2
        
        return simd.float3x2(float2(Float(s), 0.0), float2(0.0, -Float(s)), float2(Float(dx), Float(dy)))
    }
    
    var rotation = matrix_identity_float3x3
    var background = float4(0.0)
    var lighting = float4(0.0)
    
    // MARK: solid body dynamics
    var w = float3.zero
    var omega = float3.zero
    var target = float3.zero
    
    private let gamma: Float = 8.0
    private let kappa: Float = 16.0
    
    func step2(_ dt: Double) {
        w += omega * Float(dt/2.0)
        omega -= (gamma*omega + kappa*(w-target)) * Float(dt)
        w += omega * Float(dt/2.0)
    }
    
    func step6(_ dt: Double) {
        let w: [Double] = [
             1.31518632068391121888424972823886251,
            -1.17767998417887100694641568096431573,
             0.235573213359358133684793182978534602,
             0.784513610477557263819497633866349876
        ]
        
        for i in -3...3 { step2(w[abs(i)]*dt) }
    }
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        
        // initialize compute pipeline
        guard let device = MTLCreateSystemDefaultDevice(),
              let transform = device.makeBuffer(length: MemoryLayout<float3x2>.size),
              let rotation = device.makeBuffer(length: MemoryLayout<float3x3>.size),
              let bgcolor = device.makeBuffer(length: MemoryLayout<float4>.size),
              let light = device.makeBuffer(length: MemoryLayout<float4>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.queue = queue
        self.buffers = [transform, rotation, bgcolor, light]
        
        layer?.isOpaque = false
        framebufferOnly = false
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let shader = shaders[projection], let drawable = currentDrawable else { return }
        
        // if spinning, advance the viewpoint towards target view
        if (spin) { step6(1.0/Double(preferredFramesPerSecond)); rotation = gen2rot(w) }
        
        // if lighting effects are enabled, pass lighting to the shader
        let lighting = UserDefaults.standard.bool(forKey: lightingKey) ? self.lighting : float4(0.0)
        
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform, as: float3x2.self)
        buffers[1].contents().storeBytes(of: rotation, as: float3x3.self)
        buffers[2].contents().storeBytes(of: background, as: float4.self)
        buffers[3].contents().storeBytes(of: lighting, as: float4.self)
        
        // initialize compute command buffer
        guard let command = queue.makeCommandBuffer() else { return }
        
        // render map if available
        if let map = map {
            shader.data.encode(command: command, buffers: buffers, textures: [map.texture, drawable.texture])
        } else {
            shader.grid.encode(command: command, buffers: buffers, textures: [drawable.texture])
        }
        
        command.present(drawable)
        command.commit()
    }
}

// MARK: SO(3) group representations

// spherical coordinates to unit vector
func ang2vec(_ theta: Double, _ phi: Double) -> float3 {
    let z = cos(theta), r = sin(theta)
    
    return float3(Float(r*cos(phi)), Float(r*sin(phi)), Float(z))
}

// latitude, longitude and azimuth to rotation matrix
func ang2rot(_ theta: Double, _ phi: Double, _ psi: Double) -> float3x3 {
    let ct = Float(cos(theta)), st = Float(sin(theta))
    let cp = Float(cos(phi)), sp = Float(sin(phi))
    let ca = Float(cos(psi)), sa = Float(sin(psi))
    
    let xz = float3x3(float3(ct,0,st), float3(0,1,0), float3(-st,0,ct))
    let xy = float3x3(float3(cp,sp,0), float3(-sp,cp,0), float3(0,0,1))
    let yz = float3x3(float3(1,0,0), float3(0,ca,sa), float3(0,-sa,ca))
    
    return xz*xy*yz
}

// generator of rotation to rotation matrix
func gen2rot(_ w: float3) -> float3x3 {
    let theta = length(w); guard (theta > 0.0) else { return matrix_identity_float3x3 }
    let W = float3x3( float3(0.0,w.z,-w.y), float3(-w.z,0.0,w.x), float3(w.y,-w.x,0.0))
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
