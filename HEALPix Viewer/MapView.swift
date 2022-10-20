//
//  MapView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import MetalKit

struct MapView: NSViewRepresentable {
    typealias NSViewType = ProjectedView
    var view = ProjectedView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        view.awakeFromNib(); return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
        view.draw(view.bounds)
    }
}

class ProjectedView: MTKView {
    // MARK: compute pipeline
    var queue: MTLCommandQueue! = nil
    let shader = MetalKernel(kernel: "uniform_fill")
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        
        // initialize compute pipeline
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.queue = queue
        
        framebufferOnly = false
    }
    
    // MARK: render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
        
        // initialize compute command buffer
        guard let command = queue.makeCommandBuffer() else { return }
        shader.encode(command: command, textures: [drawable.texture])
        command.present(drawable)
        command.commit()
    }
}
