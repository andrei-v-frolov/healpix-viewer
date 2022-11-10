//
//  Map.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-09.
//

import SwiftUI
import MetalKit

// HEALPix map representation
final class Map {
    let nside: Int
    let data: [Float]
    
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let device = MTLCreateSystemDefaultDevice(),
              let buffer = device.makeBuffer(length: size)
              else { fatalError("Metal Framework could not be initalized") }
        
        buffer.contents().storeBytes(of: data, as: [Float].self)
        
        return buffer
    }()
    
    // Metal texture array representing xyf faces
    lazy var texture: MTLTexture = {
        // texture format
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba32Float, width: nside, height: nside, mipmapped: false)
        
        desc.textureType = MTLTextureType.type2DArray
        desc.usage = [.shaderWrite, .shaderRead]
        desc.arrayLength = 12
        
        // initialize compute pipeline
        guard let device = MTLCreateSystemDefaultDevice(),
              let texture = device.makeTexture(descriptor: desc)
              else { fatalError("Metal Framework could not be initalized") }
        
        return texture
    }()
    
    // initialize map from array
    init(nside: Int, data: [Float]) {
        self.nside = nside
        self.data = data
    }
}

// color mapper transforms data to rendered texture array
struct ColorMapper {
    // compute pipeline
    let shader = MetalKernel(kernel: "colorize")
    let queue: MTLCommandQueue
    let buffers: [MTLBuffer]
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let colors = device.makeBuffer(length: MemoryLayout<float3x4>.size),
              let range = device.makeBuffer(length: MemoryLayout<float2>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.buffers = [colors, range]
        self.queue = queue
    }
    
    func colorize(map: Map, colormap: Colormap, mincolor: Color, maxcolor: Color, nancolor: Color, minvalue: Double, maxvalue: Double) {
        let colors = float3x4(mincolor.components, maxcolor.components, nancolor.components)
        let range = float2(Float(minvalue), Float(maxvalue))
        
        buffers[0].contents().storeBytes(of: colors, as: float3x4.self)
        buffers[1].contents().storeBytes(of: range, as: float2.self)
        
        // initialize compute command buffer
        guard let command = queue.makeCommandBuffer() else { return }
        
        shader.encode(command: command, buffers: [map.buffer, buffers[0], buffers[1]], textures: [colormap.texture, map.texture], threadsPerGrid: MTLSize(width: map.nside, height: map.nside, depth: 12))
        command.commit()
    }
}
