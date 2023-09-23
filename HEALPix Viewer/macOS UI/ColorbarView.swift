//
//  ColorbarView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-08.
//

import SwiftUI
import MetalKit

// MARK: SwiftUI wrapper for ColorbarView
struct BarView: NSViewRepresentable {
    @Binding var colorbar: MTLTexture
    @Binding var background: Color
    @Binding var barview: ColorbarView?
    var thickness: Double = 1.0
    var grid: Bool = false
    
    typealias NSViewType = ColorbarView
    var view = ColorbarView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        DispatchQueue.main.async { barview = view }
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        view.colorbar = colorbar
        view.background = background.components
        view.thickness = thickness
        view.grid = grid
        
        view.draw()
    }
}

// MARK: Metal renderer for color bar
class ColorbarView: MTKView {
    // MARK: compute pipeline
    static let inflight = 3; private var index = 0
    private var semaphore = DispatchSemaphore(value: inflight)
    private var buffers = [[MTLBuffer]]()
    
    // MARK: colorbar shader
    let shader = (bar: MetalKernel(kernel: "colorbar"), grid: MetalKernel(kernel: "colorgrid"))
    
    // MARK: state variables
    var colorbar = ColorScheme.defaultValue.colormap.texture
    var thickness = 1.0
    var padding = 0.1
    var grid = false
    
    // default geometry
    static let aspect = 30.0
    
    // MARK: affine tranform mapping screen to projection plane
    func transform(width: Double? = nil, height: Double? = nil, padding: Double? = nil) -> float3x2 {
        let w = width ?? drawableSize.width, h = height ?? drawableSize.height
        let aspect = ColorbarView.aspect/thickness, x = 1.0, y = x/aspect, p = padding ?? self.padding
        let s = max((1.0+p) * x/w, y/h), dx = -s*w/2 + 0.5, dy = aspect*s*h/2 + 0.5
        
        return simd.float3x2(float2(Float(s), 0.0), float2(0.0, -Float(aspect*s)), float2(Float(dx), Float(dy)))
    }
    
    // MARK: arguments to shader
    var background = float4(0.0)
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        self.device = metal.device
        
        // initialize compute pipeline buffers
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        
        for _ in 0..<Self.inflight {
            guard let transform = metal.device.makeBuffer(length: MemoryLayout<float3x2>.size, options: options),
                  let bgcolor = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options)
                  else { fatalError("Could not allocate parameter buffers in colorbar view") }
            
            self.buffers.append([transform, bgcolor])
        }
        
        // view options
        layer?.isOpaque = false
        framebufferOnly = false
        presentsWithTransaction = true
        
        // redraw on notification
        isPaused = true
        enableSetNeedsDisplay = true
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
    func encode(_ command: MTLCommandBuffer, from colorbar: MTLTexture? = nil, to texture: MTLTexture, transform: float3x2? = nil, background: float4? = nil) {
        // wait for available buffer
        semaphore.wait()
        index = (index+1) % Self.inflight
        let buffers = self.buffers[index]
        
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform ?? self.transform(), as: float3x2.self)
        buffers[1].contents().storeBytes(of: background ?? self.background, as: float4.self)
        
        // render colorbar
        let colorbar = colorbar ?? self.colorbar, shader = grid ? shader.grid : shader.bar
        shader.encode(command: command, buffers: buffers, textures: [colorbar, texture])
        command.addCompletedHandler { _ in self.semaphore.signal() }
    }
    
    // MARK: render image to off-screen texture
    func render(from colorbar: MTLTexture? = nil, to texture: MTLTexture) {
        let transform = transform(width: Double(texture.width), height: Double(texture.height), padding: 0.0)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        // encode render command
        encode(command, from: colorbar, to: texture, transform: transform)
        command.commit(); command.waitUntilCompleted()
    }
}
