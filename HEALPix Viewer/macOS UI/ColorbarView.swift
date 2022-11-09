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
    @Binding var colorsheme: ColorScheme
    @Binding var background: Color
    
    typealias NSViewType = ColorbarView
    var view = ColorbarView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        view.colormap = colorsheme.colormap
        view.background = background.components
        
        view.draw(view.bounds)
    }
}

// MARK: Metal renderer for color bar
class ColorbarView: MTKView {
    // MARK: compute pipeline
    var queue: MTLCommandQueue! = nil
    var buffers = [MTLBuffer]()
    
    // MARK: colorbar shader
    let shader = MetalKernel(kernel: "colorbar")
    
    // MARK: state variables
    var colormap = ColorScheme.defaultValue.colormap
    var padding = 0.1
    let aspect = 20.0
    
    // MARK: arguments to shader
    var transform: float3x2 {
        let x = 1.0, y = x/aspect, w = drawableSize.width, h = drawableSize.height
        let s = max((1.0+2.0*padding) * x/w, y/h), dx = -s*w/2 + 0.5, dy = aspect*s*h/2 + 0.5
        
        return simd.float3x2(float2(Float(s), 0.0), float2(0.0, -Float(aspect*s)), float2(Float(dx), Float(dy)))
    }
    
    var background = float4(0.0)
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        
        // initialize compute pipeline
        guard let device = MTLCreateSystemDefaultDevice(),
              let transform = device.makeBuffer(length: MemoryLayout<float3x2>.size),
              let bgcolor = device.makeBuffer(length: MemoryLayout<float4>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.queue = queue
        self.buffers = [transform, bgcolor]
        
        layer?.isOpaque = false
        framebufferOnly = false
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
        
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform, as: float3x2.self)
        buffers[1].contents().storeBytes(of: background, as: float4.self)
        
        // initialize compute command buffer
        guard let command = queue.makeCommandBuffer() else { return }
        shader.encode(command: command, buffers: buffers, textures: [colormap.texture, drawable.texture])
        command.present(drawable)
        command.commit()
    }
}
