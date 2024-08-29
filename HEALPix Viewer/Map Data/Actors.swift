//
//  Actors.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-27.
//

import SwiftUI
import MetalKit

// correlator computes average and covariance matrix
struct Correlator {
    // compute pipeline
    let shader = MetalKernel(kernel: "covariance")
    let buffer: (range: MTLBuffer, npix: MTLBuffer, cov: MTLBuffer, pts: MTLBuffer)
    let threads: Int
    
    init() {
        // wider than this will break covariance kernel barriers
        let threads = metal.device.maxThreadsPerThreadgroup.width
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let range = metal.device.makeBuffer(length: MemoryLayout<float2x3>.size, options: options),
              let npix = metal.device.makeBuffer(length: MemoryLayout<uint2>.size, options: options),
              let cov = metal.device.makeBuffer(length: MemoryLayout<float3x3>.size*threads),
              let pts = metal.device.makeBuffer(length: MemoryLayout<uint>.size*threads)
              else { fatalError("Could not allocate parameter buffers in correlator") }
        
        self.threads = threads
        self.buffer = (range, npix, cov, pts)
    }
    
    func correlate(_ x: Map, _ y: Map, _ z: Map) -> (avg: double3, cov: double3x3)? {
        let nside = x.nside, npix = x.npix; guard (y.nside == nside && z.nside == nside) else { return nil }
        
        // limit covariance sampling to nside=1024 subset and data within range
        let skip = max(2.0*log2(Double(nside)/1024.0), 0)
        buffer.npix.contents().storeBytes(of: uint2(uint(npix),uint(skip)), as: uint2.self)
        buffer.range.contents().storeBytes(of: float2x3(
            float3(Float(x.min),Float(y.min),Float(z.min)),
            float3(Float(x.max),Float(y.max),Float(z.max))), as: float2x3.self)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return nil }
        
        shader.encode(command: command, buffers: [x.buffer, y.buffer, z.buffer, buffer.range, buffer.npix, buffer.cov, buffer.pts],
            textures: [], threadsPerGrid: MTLSize(width: threads, height: 1, depth: 1))
        command.commit(); command.waitUntilCompleted()
        
        // read off accumulated values
        let n = buffer.pts.contents().bindMemory(to: uint.self, capacity: threads)[0]
        let S = buffer.cov.contents().bindMemory(to: float3x3.self, capacity: threads)[0]
        let A = double3(S[0])/Double(n), B = double3(S[1])/Double(n), C = double3(S[2])/Double(n)
        
        // covariance via König's formula (not the best way, but good enough)
        let cov = double3x3(
            double3(B[0] - A.x*A.x, C[0] - A.x*A.y, C[1] - A.x*A.z),
            double3(C[0] - A.y*A.x, B[1] - A.y*A.y, C[2] - A.y*A.z),
            double3(C[1] - A.z*A.x, C[2] - A.z*A.y, B[2] - A.z*A.z)
        )
        
        return (A, cov)
    }
}

// color mixer transforms data to false color texture array
struct ColorMixer {
    // compute pipeline
    let shader = Primaries.shaders(kernel: "mix")
    let buffer: (mixer: MTLBuffer, gamma: MTLBuffer, nan: MTLBuffer)
    
    init() {
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let mixer = metal.device.makeBuffer(length: MemoryLayout<float4x4>.size, options: options),
              let gamma = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options),
              let nan = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in color mixer") }
        
        self.buffer = (mixer, gamma, nan)
    }
    
    func mix(_ x: MapData, _ y: MapData, _ z: MapData, decorrelate: Decorrelator, primaries: Primaries, nan: Color, output texture: MTLTexture) {
        let nside = texture.width; guard (x.data.nside == nside && y.data.nside == nside && z.data.nside == nside) else { return }
        
        // input data range
        let range = (x: x.range, y: y.range, z: z.range)
        let x = x.available, y = y.available, z = z.available
        let v = double3(range.x?.min ?? x.min, range.y?.min ?? y.min, range.z?.min ?? z.min)
        let w = double3(range.x?.max ?? x.max, range.y?.max ?? y.max, range.z?.max ?? z.max)
        
        // input data scaling
        let scale = double3x3(diagonal: 1.0/(w-v))
        
        // decorrelation matrix
        let S = pca(covariance: scale*decorrelate.cov*scale, alpha: decorrelate.alpha, beta: decorrelate.beta) * scale
        let shift = (decorrelate.avg-v)/(w-v) - S * decorrelate.avg
        
        // color mixing matrix (optionally enforcing r+g+b = white)
        let mixer = primaries.mixer*double4x4(double4(S[0],0), double4(S[1],0), double4(S[2],0), double4(shift,1))
        
        buffer.mixer.contents().storeBytes(of: float4x4(mixer), as: float4x4.self)
        buffer.gamma.contents().storeBytes(of: float4(primaries.gamma), as: float4.self)
        buffer.nan.contents().storeBytes(of: nan.components, as: float4.self)
        
        // initialize compute command buffer
        guard let shader = shader[primaries.shader],
              let command = metal.queue.makeCommandBuffer() else { return }
        
        shader.encode(command: command,
                buffers: [x.buffer, y.buffer, z.buffer, buffer.mixer, buffer.gamma, buffer.nan],
                textures: [texture], threadsPerGrid: MTLSize(width: nside, height: nside, depth: 12))
        if texture.mipmapLevelCount > 1, let encoder = command.makeBlitCommandEncoder() {
            encoder.generateMipmaps(for: texture)
            encoder.endEncoding()
        }
        command.commit()
    }
    
    // decorrelation matrix [COV^(-alpha) if alpha < 1/2, or COR^(1/2-alpha)*COV(-1/2) if alpha > 1/2]
    func pca(covariance: double3x3, alpha: Double = 0.5, beta: Double = 0.5) -> double3x3 {
        let identity = double3x3(1.0), a = min(2*alpha,1.0), b = max(2*alpha-1.0,0.0), c = beta*exp2(1.0-a)
        let scale = double3x3(diagonal: rsqrt(double3(covariance[0,0], covariance[1,1], covariance[2,2])))
        guard let (s,u,v) = covariance.svd, let (S,U,V) = (scale*covariance*scale).svd else { return identity }
        
        return c * (U*double3x3(diagonal: compress(S,b))*V) * (u*double3x3(diagonal: compress(s,a))*v)
    }
    
    // regularized inverse square root
    func compress(_ s: double3, _ gamma: Double = 1.0) -> double3 {
        // limit ill-conditioned eigenvalues
        let epsilon = s.x*s.x/1.0e8
        
        // asymptote from linear to rsqrt
        return double3(
            pow(s.x/pow(epsilon + s.x*s.x, 0.75), gamma),
            pow(s.y/pow(epsilon + s.y*s.y, 0.75), gamma),
            pow(s.z/pow(epsilon + s.z*s.z, 0.75), gamma)
        )
    }
}

// component separator extracts component given spectral weights
struct ComponentSeparator {
    // compute pipeline
    let shader = MetalKernel(kernel: "component")
    let buffer: (units: MTLBuffer, model: MTLBuffer)
    
    init() {
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let units = metal.device.makeBuffer(length: MemoryLayout<float3>.size, options: options),
              let model = metal.device.makeBuffer(length: MemoryLayout<float3x3>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in component separator") }
        
        self.buffer = (units, model)
    }
    
    // component separation via simple likelihood optimizer
    func extract(_ map: Map, x: Map, y: Map, z: Map, units: float3, model: float3x3) {
        let nside = map.nside; guard (x.nside == nside && y.nside == nside && z.nside == nside) else { return }
        
        buffer.units.contents().storeBytes(of: units, as: float3.self)
        buffer.model.contents().storeBytes(of: model, as: float3x3.self)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        shader.encode(command: command, buffers: [x.buffer, y.buffer, z.buffer, buffer.units, buffer.model, map.buffer])
        command.commit(); command.waitUntilCompleted()
    }
}

// color mapper transforms data to rendered texture array
struct ColorMapper {
    // compute pipeline
    let shader = MetalKernel(kernel: "colorize")
    let buffer: (color: MTLBuffer, range: MTLBuffer)
    
    init() {
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let color = metal.device.makeBuffer(length: MemoryLayout<float3x4>.size, options: options),
              let range = metal.device.makeBuffer(length: MemoryLayout<float2>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in color mapper") }
        
        self.buffer = (color, range)
    }
    
    func colorize(map: Map, color: Palette, range: Bounds, output texture: MTLTexture) {
        let nside = texture.width; guard (map.nside == nside) else { return }
        let colors = float3x4(color.min.components, color.max.components, color.nan.components)
        let range = float2(Float(range.min), Float(range.max))
        
        buffer.color.contents().storeBytes(of: colors, as: float3x4.self)
        buffer.range.contents().storeBytes(of: range, as: float2.self)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        shader.encode(command: command, buffers: [map.buffer, buffer.color, buffer.range], textures: [color.scheme.colormap.texture, texture], threadsPerGrid: MTLSize(width: nside, height: nside, depth: 12))
        if texture.mipmapLevelCount > 1, let encoder = command.makeBlitCommandEncoder() {
            encoder.generateMipmaps(for: texture)
            encoder.endEncoding()
        }
        command.commit()
    }
}

// data transformer applies a poitwise function to a map
struct DataTransformer {
    // compute pipeline
    let shaders: [Function: MetalKernel] = [
        .log:       MetalKernel(kernel: "log_transform"),
        .asinh:     MetalKernel(kernel: "asinh_transform"),
        .atan:      MetalKernel(kernel: "atan_transform"),
        .tanh:      MetalKernel(kernel: "tanh_transform"),
        .power:     MetalKernel(kernel: "pow_transform"),
        .exp:       MetalKernel(kernel: "exp_transform"),
        .normalize: MetalKernel(kernel: "norm_transform")
    ]
    
    let buffer: MTLBuffer
    
    init() {
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let params = metal.device.makeBuffer(length: MemoryLayout<float2>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in data transformer") }
        
        self.buffer = params
    }
    
    func apply(map: Map, transform: Transform, recycle: GpuMap? = nil) -> GpuMap? {
        guard let shader = shaders[transform.f],
              let buffer = recycle?.buffer ?? metal.device.makeBuffer(length: map.size),
              let command = metal.queue.makeCommandBuffer() else { return nil }
        
        let output = recycle ?? GpuMap(nside: map.nside, buffer: buffer, min: 0.0, max: 0.0)
        let params = float2(Float(transform.mu), Float(exp(transform.sigma)))
        guard (output.nside == map.nside) else { return nil }
        
        self.buffer.contents().storeBytes(of: params, as: float2.self)
        shader.encode(command: command, buffers: [map.buffer, output.buffer, self.buffer])
        command.commit()
        
        // transformed CDF and bounds
        if (transform.f == .normalize) {
            let delta = 2.0/Double(map.npix-1)
            output.min = sqrt2 * erfinv(delta - 1.0)
            output.max = sqrt2 * erfinv(Double(map.npix-2)*delta - 1.0)
            output.cdf = nil
        } else {
            output.min = transform.eval(map.min)
            output.max = transform.eval(map.max)
            output.cdf = map.cdf?.map { transform.eval($0) }
        }
        
        return output
    }
}
