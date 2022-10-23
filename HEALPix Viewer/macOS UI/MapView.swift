//
//  MapView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import MetalKit

struct MapView: NSViewRepresentable {
    @Binding var magnification: Double
    
    typealias NSViewType = ProjectedView
    var view = ProjectedView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        view.magnification = magnification
        
        view.draw(view.bounds)
    }
}

class ProjectedView: MTKView {
    // MARK: compute pipeline
    var queue: MTLCommandQueue! = nil
    let shader = MetalKernel(kernel: "mollweide_grid")
    var buffers = [MTLBuffer]()
    
    // MARK: state variables
    var projection = Projection.mollweide
    var magnification = 0.0
    var padding = 0.1
    
    // MARK: ...
    var transform: float3x2 {
        let (x,y) = projection.extent, w = drawableSize.width, h = drawableSize.height
        let s = 2.0 * (1.0+padding) * max(x/w, y/h)/exp2(magnification), dx = -s*w/2, dy = s*h/2
        
        return simd.float3x2(float2(Float(s), 0.0), float2(0.0, -Float(s)), float2(Float(dx), Float(dy)))
    }
    
    let rotation = matrix_identity_float3x3;
    let background = float4(1.0, 1.0, 0.0, 0.5);
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        
        // initialize compute pipeline
        guard let device = MTLCreateSystemDefaultDevice(),
              let transform = device.makeBuffer(length: MemoryLayout<float3x2>.size),
              let rotation = device.makeBuffer(length: MemoryLayout<float3x3>.size),
              let bgcolor = device.makeBuffer(length: MemoryLayout<float4>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.queue = queue
        self.buffers = [transform, rotation, bgcolor]
        
        layer?.isOpaque = false
        framebufferOnly = false
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
        
        // load arguments to be passed to kernel
        buffers[0].contents().storeBytes(of: transform, as: float3x2.self)
        buffers[1].contents().storeBytes(of: rotation, as: float3x3.self)
        buffers[2].contents().storeBytes(of: background, as: float4.self)
        
        // initialize compute command buffer
        guard let command = queue.makeCommandBuffer() else { return }
        shader.encode(command: command, buffers: buffers, textures: [drawable.texture])
        command.present(drawable)
        command.commit()
    }
}
