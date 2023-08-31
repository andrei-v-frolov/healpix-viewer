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
        let device = provided ?? metal.device
        
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: kernel),
              let state = try? device.makeComputePipelineState(function: function)
              else { fatalError("Unable to create pipeline state for kernel \(kernel)()") }
        
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
    
    // copy buffer
    var copy: MTLBuffer {
        guard let buffer = metal.device.makeBuffer(length: length),
              let command = metal.queue.makeCommandBuffer(),
              let encoder = command.makeBlitCommandEncoder()
              else { fatalError("Could not allocate buffer") }
        
        encoder.copy(from: self, sourceOffset: 0, to: buffer, destinationOffset: 0, size: length)
        encoder.endEncoding(); command.commit(); return buffer
    }
}

// MARK: convenience extensions to MTLTexture
extension MTLTexture {
    // texture size and CIImage-style extent
    var size: MTLSize { return MTLSize(width: width, height: height, depth: depth) }
    var extent: CGRect { return CGRect(x: 0, y: 0, width: width, height: height) }
    
    // texture format properties (not all combinations supported by CGContext!)
    var bits: Int {
        switch self.pixelFormat {
            case .a8Unorm, .r8Unorm, .r8Uint: return 8
            case .r16Unorm, .r16Uint, .r16Float, .rg8Unorm, .rg8Uint, .abgr4Unorm: return 16
            case .r32Uint, .r32Float, .rg16Unorm, .rg16Uint, .rg16Float, .rgba8Unorm, .rgba8Uint, .bgra8Unorm: return 32
            case .rg32Uint, .rg32Float, .rgba16Unorm, .rgba16Uint, .rgba16Float: return 64
            case .rgba32Uint, .rgba32Float: return 128
            default: fatalError("texture layout is not supported")
        }
    }
    
    var components: Int {
        switch self.pixelFormat {
            case .a8Unorm, .r8Unorm, .r8Uint, .r16Unorm, .r16Uint, .r16Float, .r32Uint, .r32Float: return 1
            case .rg8Unorm, .rg8Uint, .rg16Unorm, .rg16Uint, .rg16Float, .rg32Uint, .rg32Float: return 2
            case .abgr4Unorm, .rgba8Unorm, .rgba8Uint, .bgra8Unorm, .rgba16Unorm, .rgba16Uint, .rgba16Float, .rgba32Uint, .rgba32Float: return 4
            default: fatalError("texture layout is not supported")
        }
    }
    
    var layout: UInt32 {
        switch self.pixelFormat {
            case .a8Unorm: return CGImageAlphaInfo.alphaOnly.rawValue
            case .r8Unorm, .r8Uint, .r16Unorm, .r16Uint, .rg8Unorm, .rg8Uint, .r32Uint, .rg16Unorm, .rg16Uint, .rg32Uint: return CGImageAlphaInfo.none.rawValue
            case .r16Float, .r32Float, .rg16Float, .rg32Float: return CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue
            case .abgr4Unorm: return CGImageAlphaInfo.premultipliedFirst.rawValue
            case .rgba8Unorm, .rgba8Uint, .bgra8Unorm, .rgba16Unorm, .rgba16Uint, .rgba32Uint: return CGImageAlphaInfo.premultipliedLast.rawValue
            case .rgba16Float, .rgba32Float: return CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue
            default: fatalError("texture layout is not supported")
        }
    }
}
