//
//  MetalShader.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-20.
//

import Foundation
import MetalKit

// MARK: protocol encapsulating a Metal operation that can be encoded into a single command buffer
protocol MetalShader {
    var name: String { get }
    
    // encode shader to command buffer specified
    func encode(command: MTLCommandBuffer, buffers: [MTLBuffer])
    func encode(command: MTLCommandBuffer, buffers: MTLBuffer...)
    func encode(command: MTLCommandBuffer, textures: [MTLTexture])
    func encode(command: MTLCommandBuffer, textures: MTLTexture...)
    func encode(command: MTLCommandBuffer, buffers: [MTLBuffer], textures: [MTLTexture], threadsPerGrid: MTLSize?)
    func encode(command: MTLCommandBuffer, buffers: [Int: MTLBuffer], textures: [Int: MTLTexture], threadsPerGrid: MTLSize)
}

extension MetalShader {
    // default implementation of encode with arguments passed as dictionaries
    func encode(command: MTLCommandBuffer, buffers buffer: [Int: MTLBuffer], textures texture: [Int: MTLTexture], threadsPerGrid: MTLSize) {
        var buffers = [MTLBuffer](), i = 0
        buffers.reserveCapacity(buffer.count)
        while let b = buffer[i] { buffers.append(b); i += 1 }
        
        var textures = [MTLTexture](), j = 0
        textures.reserveCapacity(texture.count)
        while let t = texture[j] { textures.append(t); j += 1 }
        
        encode(command: command, buffers: buffers, textures: textures, threadsPerGrid: threadsPerGrid)
    }
    
    // convenience encoders which operate on buffers only
    func encode(command: MTLCommandBuffer, buffers: [MTLBuffer]) {
        encode(command: command, buffers: buffers, textures: [], threadsPerGrid: nil)
    }
    
    func encode(command: MTLCommandBuffer, buffers literal: MTLBuffer...) {
        encode(command: command, buffers: literal, textures: [], threadsPerGrid: nil)
    }
    
    // convenience encoders which operate on textures only
    func encode(command: MTLCommandBuffer, textures: [MTLTexture]) {
        encode(command: command, buffers: [], textures: textures, threadsPerGrid: nil)
    }
    
    func encode(command: MTLCommandBuffer, textures literal: MTLTexture...) {
        encode(command: command, buffers: [], textures: literal, threadsPerGrid: nil)
    }
}

// MARK: structure encapsulating a single Metal compute function
struct MetalKernel: MetalShader {
    let name: String
    let state: MTLComputePipelineState
    var threadsPerGroup1D: MTLSize
    var threadsPerGroup2D: MTLSize
    var threadsPerGroup3D: MTLSize { threadsPerGroup2D }
    
    // main initializer
    init(kernel: String, device provided: MTLDevice? = nil) {
        guard let device = provided ?? MTLCreateSystemDefaultDevice()
            else { fatalError("Metal Framework could not be initalized") }
        
        guard let library = device.makeDefaultLibrary(),
            let function = library.makeFunction(name: kernel),
            let state = try? device.makeComputePipelineState(function: function)
            else { fatalError("Unable to create pipeline state for kernel function \(kernel)") }
        
        // compute pipeline
        self.name = kernel
        self.state = state
        
        // default thread group configuration
        let threads = state.maxTotalThreadsPerThreadgroup, width = state.threadExecutionWidth
        threadsPerGroup1D = MTLSize(width: threads, height: 1, depth: 1)
        threadsPerGroup2D = MTLSize(width: width, height: threads/width, depth: 1)
    }
    
    // dispatch compute encoder threads for execution
    func dispatch(_ encoder: MTLComputeCommandEncoder, threadsPerGrid: MTLSize) {
        // dispatchThreads does not work on devices as recent as iPhone 7
        // encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        
        // dispatch thread groups to cover entire grid
        if (threadsPerGrid.depth > 1) {
            let w = (threadsPerGrid.width + threadsPerGroup3D.width - 1)/threadsPerGroup3D.width
            let h = (threadsPerGrid.height + threadsPerGroup3D.height - 1)/threadsPerGroup3D.height
            let d = (threadsPerGrid.depth + threadsPerGroup3D.depth - 1)/threadsPerGroup3D.depth
            
            let groupsPerGrid = MTLSize(width: w, height: h, depth: d)
            encoder.dispatchThreadgroups(groupsPerGrid, threadsPerThreadgroup: threadsPerGroup3D)
        } else if (threadsPerGrid.height > 1) {
            let w = (threadsPerGrid.width + threadsPerGroup2D.width - 1)/threadsPerGroup2D.width
            let h = (threadsPerGrid.height + threadsPerGroup2D.height - 1)/threadsPerGroup2D.height
            
            let groupsPerGrid = MTLSize(width: w, height: h, depth: 1)
            encoder.dispatchThreadgroups(groupsPerGrid, threadsPerThreadgroup: threadsPerGroup2D)
        } else {
            let w = (threadsPerGrid.width + threadsPerGroup1D.width - 1)/threadsPerGroup1D.width
            
            let groupsPerGrid = MTLSize(width: w, height: 1, depth: 1)
            encoder.dispatchThreadgroups(groupsPerGrid, threadsPerThreadgroup: threadsPerGroup1D)
        }
    }
    
    // encode kernel into provided command buffer, with arguments passed as dictionaries
    func encode(command: MTLCommandBuffer, buffers: [Int: MTLBuffer], textures: [Int: MTLTexture], threadsPerGrid: MTLSize) {
        // initialize compute command encoder for kernel execution
        guard let encoder = command.makeComputeCommandEncoder() else { return }
        
        // encode kernel for execution and set its arguments
        encoder.setComputePipelineState(state)
        for (index, buffer) in buffers { encoder.setBuffer(buffer, offset: 0, index: index) }
        for (index, texture) in textures { encoder.setTexture(texture, index: index) }
        
        // dispatch compute pass and end command encoding
        dispatch(encoder, threadsPerGrid: threadsPerGrid); encoder.endEncoding()
    }
    
    // encode kernel into provided command buffer, with arguments passed as arrays
    func encode(command: MTLCommandBuffer, buffers: [MTLBuffer], textures: [MTLTexture], threadsPerGrid provided: MTLSize? = nil) {
        // initialize compute command encoder for kernel execution
        guard let threadsPerGrid = provided ?? textures.last?.size ?? buffers.first?.size else { return }
        guard let encoder = command.makeComputeCommandEncoder() else { return }
        
        // encode kernel for execution and set its arguments
        encoder.setComputePipelineState(state)
        for (index, buffer) in buffers.enumerated() { encoder.setBuffer(buffer, offset: 0, index: index) }
        for (index, texture) in textures.enumerated() { encoder.setTexture(texture, index: index) }
        
        // dispatch compute pass and end command encoding
        dispatch(encoder, threadsPerGrid: threadsPerGrid); encoder.endEncoding()
    }
}

// MARK: convenience extensions to MTLBuffer
extension MTLBuffer {
    var size: MTLSize { return MTLSize(width: length/MemoryLayout<Float>.size, height: 1, depth: 1) }
}

// MARK: convenience extensions to MTLTexture
extension MTLTexture {
    // texture size and CIImage-style extent
    var size: MTLSize { return MTLSize(width: width, height: height, depth: depth) }
    var extent: CGRect { return CGRect(x: 0, y: 0, width: width, height: height) }
}
