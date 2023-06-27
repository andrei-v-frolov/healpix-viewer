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
    var texture: MTLTexture { get }
    
    var state: ColorBar? { get set }
}

extension Map {
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
}

// HEALPix map texture array
func HPXTexture(nside: Int) -> MTLTexture {
    // texture format
    let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: TextureFormat.value.pixel, width: nside, height: nside, mipmapped: AntiAliasing.value != .none)
    
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
func IMGTexture(width: Int, height: Int) -> MTLTexture {
    // texture format
    let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: ImageFormat.value.pixel, width: width, height: height, mipmapped: false)
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
    
    // Metal texture array representing xyf faces
    lazy var texture: MTLTexture = HPXTexture(nside: nside)
    
    // current colorbar state
    internal var state: ColorBar? = nil
    
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
    
    // Metal texture array representing xyf faces
    lazy var texture: MTLTexture = HPXTexture(nside: nside)
    
    // current colorbar state
    internal var state: ColorBar? = nil
    
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
    
    // Metal texture array representing xyf faces
    lazy var texture: MTLTexture = HPXTexture(nside: nside)
    
    // current colorbar state
    internal var state: ColorBar? = nil
    
    // initialize map from buffer
    init(nside: Int, buffer: MTLBuffer, min: Double, max: Double) {
        self.nside = nside
        self.buffer = buffer
        
        self.min = min
        self.max = max
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
    
    func colorize(map: Map, color: Palette, range: Bounds) {
        let colors = float3x4(color.min.components, color.max.components, color.nan.components)
        let range = float2(Float(range.min), Float(range.max))
        
        buffer.color.contents().storeBytes(of: colors, as: float3x4.self)
        buffer.range.contents().storeBytes(of: range, as: float2.self)
        
        // initialize compute command buffer
        guard let command = metal.queue.makeCommandBuffer() else { return }
        
        shader.encode(command: command, buffers: [map.buffer, buffer.color, buffer.range], textures: [color.scheme.colormap.texture, map.texture], threadsPerGrid: MTLSize(width: map.nside, height: map.nside, depth: 12))
        if map.texture.mipmapLevelCount > 1, let encoder = command.makeBlitCommandEncoder() {
            encoder.generateMipmaps(for: map.texture)
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
        
        // reset colorbar after transform
        output.state = nil
        
        return output
    }
}

// erfinv from Mike Giles, single precision
func erfinv(_ x: Double) -> Double {
    var w = -log((1.0-x)*(1.0+x)), p = 0.0
    
    if (w < 5.0) {
        w = w - 2.5
        p =  2.81022636e-08
        p =  3.43273939e-07 + p*w
        p = -3.52338770e-06 + p*w
        p = -4.39150654e-06 + p*w
        p =   0.00021858087 + p*w
        p =  -0.00125372503 + p*w
        p =  -0.00417768164 + p*w
        p =     0.246640727 + p*w
        p =      1.50140941 + p*w
    } else {
        w = sqrt(w) - 3.0
        p = -0.000200214257
        p =  0.000100950558 + p*w
        p =   0.00134934322 + p*w
        p =  -0.00367342844 + p*w
        p =   0.00573950773 + p*w
        p =  -0.00762246130 + p*w
        p =   0.00943887047 + p*w
        p =      1.00167406 + p*w
        p =      2.83297682 + p*w
    }
    
    return p*x
}
