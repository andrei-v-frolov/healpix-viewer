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
    lazy var data: [Float] = { Array(UnsafeBufferPointer(start: ptr, count: npix)) }()
    
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
    
    // data bounds
    let min: Double
    let max: Double
    
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
    deinit { ptr.deallocate() }
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
        .log:   MetalKernel(kernel: "log_transform"),
        .asinh: MetalKernel(kernel: "asinh_transform"),
        .atan:  MetalKernel(kernel: "atan_transform"),
        .tanh:  MetalKernel(kernel: "tanh_transform")
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
        
        output.min = function.f(map.min, mu: mu, sigma: sigma)
        output.max = function.f(map.max, mu: mu, sigma: sigma)
        
        return output
    }
}

// test map
var test: HpxMap = {
    let nside = 32
    let seq = [Int](0..<12*nside*nside)
    let data = seq.map { Float($0)/Float(12*nside*nside-1) }
    let map = HpxMap(nside: nside, data: data, min: 0.0, max: 1.0)
    
    let mapper = ColorMapper()
    
    mapper.colorize(map: map, colormap: Colormap.planck, mincolor: Color.blue, maxcolor: Color.red, nancolor: Color.green, minvalue: 0.0, maxvalue: 1.0)
    
    return map
}()
