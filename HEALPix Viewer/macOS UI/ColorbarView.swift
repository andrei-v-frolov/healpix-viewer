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
    @Binding var palette: Palette
    @Binding var barview: ColorbarView?
    
    typealias NSViewType = ColorbarView
    var view = ColorbarView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        DispatchQueue.main.async { barview = view }
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        view.colormap = palette.scheme.colormap
        view.background = palette.bg.components
        
        view.draw(view.bounds)
    }
}

// MARK: Metal renderer for color bar
class ColorbarView: MTKView {
    // MARK: compute pipeline
    var buffers = [MTLBuffer]()
    
    // MARK: colorbar shader
    let shader = MetalKernel(kernel: "colorbar")
    
    // MARK: state variables
    var colormap = ColorScheme.defaultValue.colormap
    var padding = 0.1
    static let aspect = 30.0
    
    // MARK: affine tranform mapping screen to projection plane
    func transform(width: Double? = nil, height: Double? = nil, padding: Double? = nil) -> float3x2 {
        let w = width ?? drawableSize.width, h = height ?? drawableSize.height
        let aspect = ColorbarView.aspect, x = 1.0, y = x/aspect, p = padding ?? self.padding
        let s = max((1.0+p) * x/w, y/h), dx = -s*w/2 + 0.5, dy = aspect*s*h/2 + 0.5
        
        return simd.float3x2(float2(Float(s), 0.0), float2(0.0, -Float(aspect*s)), float2(Float(dx), Float(dy)))
    }
    
    // MARK: arguments to shader
    var background = float4(0.0)
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        
        // initialize compute pipeline
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let transform = metal.device.makeBuffer(length: MemoryLayout<float3x2>.size, options: options),
              let bgcolor = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in colorbar view") }
        
        self.device = metal.device
        self.buffers = [transform, bgcolor]
        
        layer?.isOpaque = false
        framebufferOnly = false
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        // encode render command to drawable
        encode(command, to: drawable.texture)
        command.present(drawable)
        command.commit()
    }
    
    // MARK: encode render to command buffer
    func encode(_ command: MTLCommandBuffer, to texture: MTLTexture, transform: float3x2? = nil, background: float4? = nil) {
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform ?? self.transform(), as: float3x2.self)
        buffers[1].contents().storeBytes(of: background ?? self.background, as: float4.self)
        
        shader.encode(command: command, buffers: buffers, textures: [colormap.texture, texture])
    }
    
    // MARK: render image to off-screen texture
    func render(to texture: MTLTexture) {
        let transform = transform(width: Double(texture.width), height: Double(texture.height), padding: 0.0)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        // encode render command
        encode(command, to: texture, transform: transform)
        command.commit(); command.waitUntilCompleted()
    }
    
    // MARK: create map image of specified size
    func image(width w: Int, height h: Int) -> MTLTexture {
        let texture = IMGTexture(width: w, height: h)
        render(to: texture); return texture
    }
}
