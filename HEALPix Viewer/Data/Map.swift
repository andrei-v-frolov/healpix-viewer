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
    var id: UUID { get }
    
    var nside: Int { get }
    var npix: Int { get }
    var size: Int { get }
    
    var min: Double { get }
    var max: Double { get }
    var cdf: [Double]? { get }
    
    var data: [Float] { get }
    var buffer: MTLBuffer { get }
    var texture: MTLTexture { get }
}

// HEALPix map texture array
func HPXTexture(nside: Int) -> MTLTexture {
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
}

// PNG image texture for export
func PNGTexture(width: Int, height: Int) -> MTLTexture {
    // texture format
    let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: width, height: height, mipmapped: false)
    desc.usage = [.shaderWrite, .shaderRead]
    
    // initialize compute pipeline
    guard let device = MTLCreateSystemDefaultDevice(),
          let texture = device.makeTexture(descriptor: desc)
          else { fatalError("Metal Framework could not be initalized") }
    
    return texture
}

// HEALPix map representation, based on Swift array
final class HpxMap: Map {
    let id: UUID
    let nside: Int
    let data: [Float]
    
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
    
    // data bounds
    let min: Double
    let max: Double
    var cdf: [Double]? = nil
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let device = MTLCreateSystemDefaultDevice(),
              let buffer = (data.withUnsafeBytes { device.makeBuffer(bytes: $0.baseAddress!, length: size) })
              else { fatalError("Metal Framework could not be initalized") }
        
        return buffer
    }()
    
    // Metal texture array representing xyf faces
    lazy var texture: MTLTexture = HPXTexture(nside: nside)
    
    // initialize map from array
    init(nside: Int, data: [Float], min: Double? = nil, max: Double? = nil) {
        self.id = UUID()
        self.nside = nside
        self.data = data
        
        self.min = min ?? Double(data.min() ?? 0.0)
        self.max = max ?? Double(data.max() ?? 0.0)
    }
}

// HEALPix map representation, based on CPU data
final class CpuMap: Map {
    let id: UUID
    let nside: Int
    let ptr: UnsafePointer<Float>
    lazy var idx: UnsafeMutablePointer<Int32> = { UnsafeMutablePointer<Int32>.allocate(capacity: npix) }()
    lazy var data: [Float] = { Array(UnsafeBufferPointer(start: ptr, count: npix)) }()
    
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
    
    // data bounds
    let min: Double
    let max: Double
    var cdf: [Double]? = nil
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let device = MTLCreateSystemDefaultDevice(),
              let buffer = device.makeBuffer(bytes: ptr, length: size)
              else { fatalError("Metal Framework could not be initalized") }
        
        return buffer
    }()
    
    // Metal texture array representing xyf faces
    lazy var texture: MTLTexture = HPXTexture(nside: nside)
    
    // initialize map from array
    init(nside: Int, buffer: UnsafePointer<Float>, min: Double, max: Double) {
        self.id = UUID()
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
    let id: UUID
    let nside: Int
    let buffer: MTLBuffer
    
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
    
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
    
    // initialize map from buffer
    init(nside: Int, buffer: MTLBuffer, min: Double, max: Double) {
        self.id = UUID()
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

// data transformer applies a poitwise function to a map
struct DataTransformer {
    // compute pipeline
    let device: MTLDevice
    let buffer: MTLBuffer
    let queue: MTLCommandQueue
    
    let shaders: [DataTransform: MetalKernel] = [
        .log:       MetalKernel(kernel: "log_transform"),
        .asinh:     MetalKernel(kernel: "asinh_transform"),
        .atan:      MetalKernel(kernel: "atan_transform"),
        .tanh:      MetalKernel(kernel: "tanh_transform"),
        .normalize: MetalKernel(kernel: "norm_transform")
    ]
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let params = device.makeBuffer(length: MemoryLayout<float2>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.buffer = params
        self.queue = queue
    }
    
    func transform(map: Map, function: DataTransform, mu: Double = 0.0, sigma: Double = 0.0, recycle: GpuMap? = nil) -> GpuMap? {
        guard let shader = shaders[function],
              let buffer = recycle?.buffer ?? device.makeBuffer(length: map.size),
              let command = queue.makeCommandBuffer() else { return nil }
        
        let output = recycle ?? GpuMap(nside: map.nside, buffer: buffer, min: 0.0, max: 0.0)
        let params = float2(Float(mu), Float(exp(sigma)))
        
        self.buffer.contents().storeBytes(of: params, as: float2.self)
        shader.encode(command: command, buffers: [map.buffer, output.buffer, self.buffer])
        command.commit()
        
        if (function == .normalize) {
            let sqrt2 = 1.414213562373095048801688724209698078569671875377
            output.min = sqrt2 * erfinv(2.0/Double(map.npix-1)-1.0)
            output.max = sqrt2 * erfinv(2.0 * Double(map.npix-2)/Double(map.npix-1)-1.0)
        } else {
            output.min = function.f(map.min, mu: mu, sigma: sigma)
            output.max = function.f(map.max, mu: mu, sigma: sigma)
            output.cdf = map.cdf?.map { function.f($0, mu: mu, sigma: sigma) }
        }
        
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
