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

// encapsulates map data, buffers, textures, and metadata
final class MapData: Identifiable, ObservableObject {
    // unique map id
    let id = UUID()
    
    // map metadata
    let file: String
    let info: String
    let name: String
    let unit: String
    let channel: Int
    
    // map data and caches
    let data: CpuMap
    var ranked: CpuMap? = nil
    var buffer: GpuMap? = nil
    
    // access backing store
    subscript(f: Function) -> Map? {
        switch f {
            case .none: return data
            case .equalize: return ranked
            default: return buffer
        }
    }
    
    // convenience wrappers
    var rendered: Map? { self[state.rendered.f] }
    var transformed: Map? { self[state.transform.f] }
    var available: Map { transformed ?? rendered ?? data }
    
    // transform corresponding to available map
    var transform: Transform {
        if (transformed != nil) { return state.transform }
        if (rendered != nil) { return state.rendered }
        return Transform()
    }
    
    // range corresponding to available map
    var range: Bounds? {
        if (transformed != nil) { return state.bounds[state.transform.f] }
        if (rendered != nil) { return state.bounds[state.rendered.f] }
        return state.bounds[.none]
    }
    
    // map face textures and preview
    let texture: MTLTexture
    let preview = IMGTexture(width: 288, height: 144)
    
    // saved view settings
    var settings: ViewState? = nil
    
    // current transform state
    internal var state = MapState()
    
    // default initializer
    init(file: String, info: String, name: String, unit: String, channel: Int, data: CpuMap) {
        self.file = file
        self.info = info
        self.name = name
        self.unit = unit
        self.channel = channel
        self.data = data
        
        // maybe we should always allocate mipmaps?
        self.texture = HPXTexture(nside: data.nside, mipmapped: AntiAliasing.value != .none)
    }
    
    // signal that map state changed
    func refresh() { self.objectWillChange.send() }
}

extension MapData: Hashable, Equatable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: MapData, b: MapData) -> Bool { a.id == b.id }
}
