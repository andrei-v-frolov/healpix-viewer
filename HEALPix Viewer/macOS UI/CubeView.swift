//
//  CubeView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-07.
//

import SwiftUI
import MetalKit

// MARK: SwiftUI wrapper for ColorCubeView
struct CubeView: NSViewRepresentable {
    // color primaries
    @AppStorage(Primaries.key) var primaries: Primaries = .defaultValue
    
    // view parameters
    @Binding var background: Color
    @Binding var cubeview: ColorCubeView?
    
    // optional parameters
    var padding: Double = 0.1
    
    typealias NSViewType = ColorCubeView
    var view = ColorCubeView()
    
    // pass parameters to ColorCubeView
    func pass(to view: Self.NSViewType) {
        view.background = background.components
        view.primaries = primaries
        view.padding = padding
    }
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        DispatchQueue.main.async { cubeview = view }
        view.awakeFromNib(); pass(to: view); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        pass(to: view); view.draw()
    }
    
    func rendered(width: Double, height: Double) -> Image? {
        view.awakeFromNib(); pass(to: view)
        
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let texture = IMGTexture(width: Int(width*scale), height: Int(height*scale))
        view.render(to: texture); return image(texture, oversample: scale)?.resizable()
    }
}

// MARK: Metal renderer for color cube
class ColorCubeView: MTKView {
    // MARK: compute pipeline
    static let inflight = 3; private var index = 0
    private var semaphore = DispatchSemaphore(value: inflight)
    private var buffers = [[MTLBuffer]]()
    
    // MARK: color cube shaders
    let shader = Primaries.shaders(kernel: "cube")
    
    // MARK: state variables
    var padding = 0.1
    
    // MARK: default geometry
    static let aspect = 3.5
    
    // MARK: affine tranform mapping screen to projection plane
    func transform(width: Double? = nil, height: Double? = nil, padding: Double? = nil, anchor: Anchor = .c, flipx: Bool? = nil, flipy: Bool = true, shiftx: Double = 0.0, shifty: Double = 0.0) -> float3x2 {
        let flipx = flipx ?? false, p = padding ?? self.padding
        let (x,y) = (Self.aspect,1.0), signx = flipx ? -1.0 : 1.0, signy = flipy ? -1.0 : 1.0
        let w = width ?? drawableSize.width, h = height ?? drawableSize.height
        let s = 2.0 * (1.0+p) * max(x/w, y/h), x0 = -s*w/2, y0 = -s*h/2
        let dx = signx*(x0 + anchor.halign*(x0+x) - s*shiftx)
        let dy = signy*y0  - anchor.valign*(y0+y) - s*shifty
        
        return simd.float3x2(float2(Float(flipx ? -s : s), 0.0), float2(0.0, Float(flipy ? -s : s)), float2(Float(dx), Float(dy)))
    }
    
    // MARK: arguments to shader
    var primaries: Primaries = .defaultValue
    var background = float4(0.0)
    
    // MARK: registered observers
    private var observer: UserDefaultsObserver? = nil
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        self.device = metal.device
        
        // initialize compute pipeline buffers
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        
        for _ in 0..<Self.inflight {
            guard let transform = metal.device.makeBuffer(length: MemoryLayout<float3x2>.size, options: options),
                  let mixer = metal.device.makeBuffer(length: MemoryLayout<float4x4>.size, options: options),
                  let gamma = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options),
                  let bgcolor = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options)
                  else { fatalError("Could not allocate parameter buffers in colorbar view") }
            
            self.buffers.append([transform, mixer, gamma, bgcolor])
        }
        
        // view options
        layer?.isOpaque = false
        framebufferOnly = false
        presentsWithTransaction = true
        
        // enable HDR output if desired
        if UserDefaults.standard.bool(forKey: hdrKey) { hdr = true }
        observer = UserDefaultsObserver(key: hdrKey) { [weak self] old, new in if let value = new as? Bool { self?.hdr = value }; self?.draw() }
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
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
    func encode(_ command: MTLCommandBuffer, to texture: MTLTexture, transform: float3x2? = nil, mixer: float4x4? = nil, gamma: float4? = nil, background: float4? = nil) {
        guard let shader = shader[primaries.shader] else { return }
        
        // wait for available buffer
        semaphore.wait()
        index = (index+1) % Self.inflight
        let buffers = self.buffers[index]
        
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform ?? self.transform(), as: float3x2.self)
        buffers[1].contents().storeBytes(of: mixer ?? float4x4(primaries.mixer), as: float4x4.self)
        buffers[2].contents().storeBytes(of: gamma ?? float4(primaries.gamma), as: float4.self)
        buffers[3].contents().storeBytes(of: background ?? self.background, as: float4.self)
        
        // render color cube
        shader.encode(command: command, buffers: buffers, textures: [texture])
        command.addCompletedHandler { _ in self.semaphore.signal() }
    }
    
    // MARK: render image to off-screen texture
    func render(to texture: MTLTexture) {
        let transform = transform(width: Double(texture.width), height: Double(texture.height), padding: 0.0, flipy: false)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        // encode render command
        encode(command, to: texture, transform: transform)
        command.commit(); command.waitUntilCompleted()
    }
}
