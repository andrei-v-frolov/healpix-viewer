//
//  Random.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-31.
//

import SwiftUI
import MetalKit

// random field PDFs
enum RandomField: String, CaseIterable {
    case uniform = "Uniform"
    case gaussian = "Gaussian"
    
    // default value
    static let defaultValue: Self = .gaussian
}

// random field generator
struct RandomGenerator {
    // compute pipeline
    let shader = (uniform: MetalKernel(kernel: "random_uniform"), gaussian: MetalKernel(kernel: "random_gaussian"))
    let buffer: MTLBuffer
    
    init() {
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let buffer = metal.device.makeBuffer(length: MemoryLayout<uint>.size, options: options)
              else { fatalError("Could not allocate seed buffer in random generator") }
        
        self.buffer = buffer
    }
    
    // generator corresponding to requested PDF
    func generator(_ pdf: RandomField) -> MetalKernel {
        switch pdf {
            case .uniform:  return shader.uniform
            case .gaussian: return shader.gaussian
        }
    }
    
    // average statistical bounds for sampled random field
    func bounds(_ pdf: RandomField, nside: Int) -> (min: Double, max: Double) {
        switch pdf {
            case .uniform:  return (0.0, 1.0)
            case .gaussian:
                let sqrt2 = 1.414213562373095048801688724209698078569671875377
                let delta = sqrt2 * erfinv(2.0/Double(12*nside*nside-1) - 1.0)
                return (-fabs(delta), fabs(delta))
        }
    }
    
    // generate random map with a requested PDF
    func generate(nside: Int, pdf: RandomField = .defaultValue, seed: Int = 0) -> GpuMap? {
        let threads = 3*nside*nside, bounds = bounds(pdf, nside: nside)
        
        // initialize compute command buffer
        guard let data = metal.device.makeBuffer(length: MemoryLayout<float4>.size*threads),
              let command = metal.queue.makeCommandBuffer() else { return nil }
        
        // pass lower 32 bits of random seed to generator
        buffer.contents().storeBytes(of: uint(seed & 0xFFFFFFFF), as: uint.self)
        
        generator(pdf).encode(command: command, buffers: [buffer, data],
            textures: [], threadsPerGrid: MTLSize(width: threads, height: 1, depth: 1))
        command.commit(); command.waitUntilCompleted()
        
        return GpuMap(nside: nside, buffer: data, min: bounds.min, max: bounds.max)
    }
    
    // header string
    func info(nside: Int, distribution: String? = nil, seed: Int = 0) -> String {
        let dist = (distribution != nil) ?  "DISTRIB = '\(distribution!.prefix(18))'" +
                   String(repeating: " ", count: 19 - min(distribution!.count,18)) +
                   "/ random number distribution\n" : ""
        return     "ALGRTHM = 'threefry4x32'       / random generator algorithm\n" + dist +
                   "SEED    =           " + String(format: "%10u", uint(seed & 0xFFFFFFFF)) + " / random generator seed\n" +
                   "NSIDE   =           " + String(format: "%10d", nside) + " / HEALPix nside"
    }
}
