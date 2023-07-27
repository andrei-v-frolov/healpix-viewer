//
//  Map.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-09.
//

import SwiftUI
import MetalKit

// HEALPix map representation
protocol Map {
    var nside: Int { get }
    var npix: Int { get }
    var size: Int { get }
    
    var min: Double { get }
    var max: Double { get }
    var cdf: [Double]? { get }
    
    var data: [Float] { get }
    var buffer: MTLBuffer { get }
}

extension Map {
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
}

// HEALPix map texture array
func HPXTexture(nside: Int, mipmapped: Bool = true) -> MTLTexture {
    // texture format
    let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: TextureFormat.value.pixel, width: nside, height: nside, mipmapped: mipmapped)
    
    desc.textureType = MTLTextureType.type2DArray
    desc.storageMode = .private
    desc.usage = [.shaderWrite, .shaderRead]
    desc.arrayLength = 12
    
    // mipmap down to nside = 16
    desc.mipmapLevelCount = max(desc.mipmapLevelCount-4, 1)
    
    // initialize compute pipeline
    guard let texture = metal.device.makeTexture(descriptor: desc)
          else { fatalError("Could not allocate map texture") }
    
    return texture
}

// PNG image texture for export
func IMGTexture(width: Int, height: Int, format: MTLPixelFormat = .rgba8Unorm) -> MTLTexture {
    // texture format
    let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: width, height: height, mipmapped: false)
    desc.usage = [.shaderWrite, .shaderRead]
    
    // initialize compute pipeline
    guard let texture = metal.device.makeTexture(descriptor: desc)
          else { fatalError("Could not allocate image texture") }
    
    return texture
}

// HEALPix map representation, based on Swift array
final class HpxMap: Map {
    let nside: Int
    let data: [Float]
    
    // data bounds
    let min: Double
    let max: Double
    var cdf: [Double]? = nil
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let buffer = (data.withUnsafeBytes { metal.device.makeBuffer(bytes: $0.baseAddress!, length: size) })
              else { fatalError("Could not allocate map buffer") }
        
        return buffer
    }()
    
    // initialize map from array
    init(nside: Int, data: [Float], min: Double? = nil, max: Double? = nil) {
        self.nside = nside
        self.data = data
        
        self.min = min ?? Double(data.min() ?? 0.0)
        self.max = max ?? Double(data.max() ?? 0.0)
    }
}

// HEALPix map representation, based on CPU data
final class CpuMap: Map {
    let nside: Int
    let ptr: UnsafePointer<Float>
    lazy var idx: UnsafeMutablePointer<Int32> = { UnsafeMutablePointer<Int32>.allocate(capacity: npix) }()
    lazy var data: [Float] = { Array(UnsafeBufferPointer(start: ptr, count: npix)) }()
    
    // data bounds
    let min: Double
    let max: Double
    var cdf: [Double]? = nil
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let buffer = metal.device.makeBuffer(bytes: ptr, length: size)
              else { fatalError("Could not allocate map buffer") }
        
        return buffer
    }()
    
    // initialize map from array
    init(nside: Int, buffer: UnsafePointer<Float>, min: Double, max: Double) {
        self.nside = nside
        self.ptr = buffer
        
        self.min = min
        self.max = max
    }
    
    // clean up on deinitialization
    deinit { ptr.deallocate(); idx.deallocate() }
    
    // index map (i.e. compute CDF)
    func index() { index_map(ptr, idx, Int32(npix)); makecdf(intervals: 1<<12) }
    
    // ranked map (i.e. equalize PDF)
    func ranked() -> CpuMap {
        let ranked = UnsafeMutablePointer<Float>.allocate(capacity: npix)
        rank_map(idx, ranked, Int32(npix))
        
        return CpuMap(nside: nside, buffer: ranked, min: 0.0, max: 1.0)
    }
    
    // decimate index to produce light-weight CDF representation
    func makecdf(intervals n: Int) {
        var cdf = [Double](); cdf.reserveCapacity(n+1)
        
        for i in stride(from: 0, through: npix, by: Swift.max(npix/n,1)) {
            let j = Swift.min(i,npix-1), x = (ptr + Int(idx[j])).pointee
            if (!x.isNaN) { cdf.append(Double(x)) }
        }
        
        self.cdf = cdf
    }
}

// HEALPix map representation, based on GPU data
final class GpuMap: Map {
    let nside: Int
    let buffer: MTLBuffer
    
    // data bounds
    var min: Double
    var max: Double
    var cdf: [Double]? = nil
    
    // array representing buffer data
    lazy var data: [Float] = {
        let ptr = buffer.contents().bindMemory(to: Float.self, capacity: npix)
        return Array(UnsafeBufferPointer(start: ptr, count: npix))
    }()
    
    // initialize map from buffer
    init(nside: Int, buffer: MTLBuffer, min: Double, max: Double) {
        self.nside = nside
        self.buffer = buffer
        
        self.min = min
        self.max = max
    }
}

// correlator computes average and covariance matrix
struct Correlator {
    // compute pipeline
    let shader = MetalKernel(kernel: "covariance")
    let buffer: (pts: MTLBuffer, cov: MTLBuffer, range: MTLBuffer, npix: MTLBuffer)
    let threads: Int
    
    init() {
        // wider than this will break covariance kernel barriers
        let threads = metal.device.maxThreadsPerThreadgroup.width
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let pts = metal.device.makeBuffer(length: MemoryLayout<uint>.size*threads),
              let cov = metal.device.makeBuffer(length: MemoryLayout<float3x3>.size*threads),
              let range = metal.device.makeBuffer(length: MemoryLayout<float2x3>.size, options: options),
              let npix = metal.device.makeBuffer(length: MemoryLayout<uint2>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in correlator") }
        
        self.threads = threads
        self.buffer = (pts, cov, range, npix)
    }
    
    func correlate(_ x: Map, _ y: Map, _ z: Map) -> (avg: float3, cov: float3x3)? {
        let nside = x.nside, npix = x.npix; guard (y.nside == nside && z.nside == nside) else { return nil }
        
        // limit covariance sampling to nside=1024 subset and data within range
        let skip = max(2.0*log2(Double(nside)/1024.0), 0)
        buffer.npix.contents().storeBytes(of: uint2(uint(npix),uint(skip)), as: uint2.self)
        buffer.range.contents().storeBytes(of: float2x3(
            float3(Float(x.min),Float(y.min),Float(z.min)),
            float3(Float(x.max),Float(y.max),Float(z.max))), as: float2x3.self)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return nil }
        
        shader.encode(command: command, buffers: [x.buffer, y.buffer, z.buffer, buffer.pts, buffer.cov, buffer.range, buffer.npix],
            textures: [], threadsPerGrid: MTLSize(width: threads, height: 1, depth: 1))
        command.commit(); command.waitUntilCompleted()
        
        // read off accumulated values
        let n = buffer.pts.contents().bindMemory(to: uint.self, capacity: threads)[0]
        let A = matrix_scale(1.0/Float(n), buffer.cov.contents().bindMemory(to: float3x3.self, capacity: threads)[0])
        
        // covariance via König's formula (not the best way, but good enough)
        let cov = float3x3(
            float3(A[1][0] - A[0].x*A[0].x, A[2][0] - A[0].x*A[0].y, A[2][1] - A[0].x*A[0].z),
            float3(A[2][0] - A[0].y*A[0].x, A[1][1] - A[0].y*A[0].y, A[2][2] - A[0].y*A[0].z),
            float3(A[2][1] - A[0].z*A[0].x, A[2][2] - A[0].z*A[0].y, A[1][2] - A[0].z*A[0].z)
        )
        
        return (A[0], cov)
    }
}

// color mixer transforms data to false color texture array
struct ColorMixer {
    // compute pipeline
    let shader = (clip: MetalKernel(kernel: "colormix_clip"),
                  comp: MetalKernel(kernel: "colormix_comp"),
                  clab: MetalKernel(kernel: "colormix_clab"),
                  glab: MetalKernel(kernel: "colormix_glab"))
    let buffer: (mixer: MTLBuffer, gamma: MTLBuffer, nan: MTLBuffer)
    
    init() {
        let options: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]
        guard let mixer = metal.device.makeBuffer(length: MemoryLayout<float4x4>.size, options: options),
              let gamma = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options),
              let nan = metal.device.makeBuffer(length: MemoryLayout<float4>.size, options: options)
              else { fatalError("Could not allocate parameter buffers in color mixer") }
        
        self.buffer = (mixer, gamma, nan)
    }
    
    func mix(_ x: MapData, _ y: MapData, _ z: MapData, decorrelate: Decorrelator, primaries: Primaries, nan: Color, compress: Bool = false, output texture: MTLTexture) {
        let nside = texture.width; guard (x.data.nside == nside && y.data.nside == nside && z.data.nside == nside) else { return }
        
        // input data range
        let range = (x: x.range, y: y.range, z: z.range)
        let x = x.available, y = y.available, z = z.available
        let v = float3(Float(range.x?.min ?? x.min), Float(range.y?.min ?? y.min), Float(range.z?.min ?? z.min))
        let w = float3(Float(range.x?.max ?? x.max), Float(range.y?.max ?? y.max), Float(range.z?.max ?? z.max))
        
        // input data scaling
        let scale = float3x3(diagonal: 1.0/(w-v))
        
        // decorrelation matrix
        let S = pca(kind: decorrelate.mode, covariance: scale*decorrelate.cov*scale, beta: decorrelate.beta) * scale
        let shift = (decorrelate.avg-v)/(w-v) - S * decorrelate.avg
        
        // color space primaries (okLab or linear device RGB)
        let lab = (primaries.mode == .blend), gamma = float4(float3(Float(exp2(primaries.gamma))), 1.0)
        let black = (lab ? float4(primaries.black.okLab) : pow(primaries.black.components, gamma))
        let white = (lab ? float4(primaries.white.okLab) : pow(primaries.white.components, gamma)) - black
        let r = (lab ? float4(primaries.r.okLab) : pow(primaries.r.components, gamma)) - black
        let g = (lab ? float4(primaries.g.okLab) : pow(primaries.g.components, gamma)) - black
        let b = (lab ? float4(primaries.b.okLab) : pow(primaries.b.components, gamma)) - black
        
        // color mixing matrix (optionally enforcing r+g+b = white)
        let q = float3x3(r.xyz, g.xyz, b.xyz).inverse * white.xyz
        let M = (primaries.mode != .add) ? float3x4(q.x*r, q.y*g, q.z*b) : float3x4(r,g,b)
        let Q = M*S, mixer = float4x4(Q[0], Q[1], Q[2], black+M*shift)
        
        buffer.mixer.contents().storeBytes(of: mixer, as: float4x4.self)
        buffer.gamma.contents().storeBytes(of: 1.0/gamma, as: float4.self)
        buffer.nan.contents().storeBytes(of: nan.components, as: float4.self)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        (lab ? (compress ? shader.glab : shader.clab) : (compress ? shader.comp : shader.clip)).encode(command: command,
                buffers: [x.buffer, y.buffer, z.buffer, buffer.mixer, buffer.gamma, buffer.nan],
                textures: [texture], threadsPerGrid: MTLSize(width: nside, height: nside, depth: 12))
        if texture.mipmapLevelCount > 1, let encoder = command.makeBlitCommandEncoder() {
            encoder.generateMipmaps(for: texture)
            encoder.endEncoding()
        }
        command.commit()
    }
    
    // decorrelation matrix
    func pca(kind: Decorrelation, covariance: float3x3, beta: Double = 0.5) -> float3x3 {
        let identity = float3x3(1.0)
        
        switch kind {
            case .none: return Float(2.0*beta)*identity
            case .cov: guard let (s,u,v) = covariance.svd else { return identity }
                return u*float3x3(diagonal: Float(beta)*compress(s))*v
            case .cor:
                let scale = float3x3(diagonal: rsqrt(float3(covariance[0,0], covariance[1,1], covariance[2,2])))
                guard let (s,u,v) = covariance.svd, let (S,U,V) = (scale*covariance*scale).svd else { return identity }
                return (U*float3x3(diagonal: compress(S))*V)*(u*float3x3(diagonal: Float(beta)*compress(s))*v)
        }
    }
    
    // regularized inverse square root
    func compress(_ s: float3) -> float3 {
        // limit ill-conditioned eigenvalues
        let epsilon = s.x*s.x/1.0e8
        
        // asymptote from linear to rsqrt
        return float3(
            s.x/pow(epsilon + s.x*s.x, 0.75),
            s.y/pow(epsilon + s.y*s.y, 0.75),
            s.z/pow(epsilon + s.z*s.z, 0.75)
        )
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
            let sqrt2 = 1.414213562373095048801688724209698078569671875377
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
