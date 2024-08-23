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
    // map size
    var nside: Int { get }
    var npix: Int { get }
    var size: Int { get }
    
    // data bounds
    var min: Double { get }
    var max: Double { get }
    
    // data access
    var data: [Float] { get }
    var ptr: UnsafePointer<Float> { get }
    var buffer: MTLBuffer { get }
    
    // copy data
    var copy: Self { get }
    
    // data indexing
    var idx: UnsafeBufferPointer<Int32> { get }
    var cdf: [Double]? { get }
    func index()
}

extension Map {
    // computed properties
    var npix: Int { return 12*nside*nside }
    var size: Int { npix * MemoryLayout<Float>.size }
    
    // create index of map values (32-bit for performance, good to nside = 8192)
    func makeidx() -> UnsafeBufferPointer<Int32> {
        let idx = UnsafeMutablePointer<Int32>.allocate(capacity: npix)
        var nobs: Int32 = 0; index_map(ptr, Int32(npix), idx, &nobs)
        return UnsafeBufferPointer(start: idx, count: Int(nobs))
    }
    
    // decimate index to produce light-weight CDF representation
    func makecdf(intervals n: Int) -> [Double]? {
        var cdf = [Double](); cdf.reserveCapacity(n+1)
        
        for i in stride(from: 0, through: idx.count, by: Swift.max(idx.count/n,1)) {
            let j = Swift.min(i,idx.count-1), x = (ptr + Int(idx[j])).pointee
            if (x.isFinite) { cdf.append(Double(x)) }
        }
        
        return cdf
    }
    
    // ranked map (i.e. PDF equalization)
    func ranked() -> CpuMap {
        let ranked = UnsafeMutablePointer<Float>.allocate(capacity: npix)
        ranked.initialize(repeating: .nan, count: npix)
        rank_map(ptr, idx.baseAddress, Int32(idx.count), ranked)
        return CpuMap(nside: nside, buffer: ranked, min: 0.0, max: 1.0)
    }
}

// HEALPix map texture array
func HPXTexture(nside: Int, format: MTLPixelFormat? = nil, mipmapped: Bool = true) -> MTLTexture {
    // texture format
    let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format ?? TextureFormat.value.pixel, width: nside, height: nside, mipmapped: mipmapped)
    
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
final class BaseMap: Map {
    // primary data
    let nside: Int
    let data: [Float]
    
    // data bounds
    let min: Double
    let max: Double
    var cdf: [Double]? = nil
    
    // data representations
    lazy var idx: UnsafeBufferPointer<Int32> = { indexed = true; return makeidx() }()
    lazy var ptr: UnsafePointer<Float> = { data.withUnsafeBufferPointer { $0.baseAddress! } }()
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let buffer = metal.device.makeBuffer(bytes: ptr, length: size)
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
    
    // map copy
    var copy: Self { Self(nside: nside, data: data, min: min, max: max) }
    
    // clean up on deinitialization
    private var indexed = false
    deinit { if indexed { idx.deallocate() } }
    
    // index map (i.e. compute CDF)
    func index() { cdf = makecdf(intervals: 1<<12) }
}

// HEALPix map representation, based on CPU-side data
final class CpuMap: Map {
    // primary data
    let nside: Int
    let ptr: UnsafePointer<Float>
    
    // data bounds
    let min: Double
    let max: Double
    var cdf: [Double]? = nil
    
    // data representations
    lazy var idx: UnsafeBufferPointer<Int32> = { indexed = true; return makeidx() }()
    lazy var data: [Float] = { Array(UnsafeBufferPointer(start: ptr, count: npix)) }()
    
    // Metal buffer containing map data
    lazy var buffer: MTLBuffer = {
        guard let buffer = metal.device.makeBuffer(bytes: ptr, length: size)
              else { fatalError("Could not allocate map buffer") }
        
        return buffer
    }()
    
    // initialize map from buffer pointer
    init(nside: Int, buffer: UnsafePointer<Float>, min: Double, max: Double) {
        self.nside = nside
        self.ptr = buffer
        
        self.min = min
        self.max = max
    }
    
    // map copy
    var copy: Self {
        let copy = UnsafeMutablePointer<Float>.allocate(capacity: npix)
        copy.initialize(from: ptr, count: npix)
        return Self(nside: nside, buffer: copy, min: min, max: max)
    }
    
    // clean up on deinitialization (we own passed pointer)
    private var indexed = false
    deinit { ptr.deallocate(); if indexed { idx.deallocate() } }
    
    // index map (i.e. compute CDF)
    func index() { cdf = makecdf(intervals: 1<<12) }
}

// HEALPix map representation, based on GPU-side data
final class GpuMap: Map {
    // primary data
    let nside: Int
    let buffer: MTLBuffer
    
    // data bounds
    var min: Double
    var max: Double
    var cdf: [Double]? = nil
    
    // data representations
    lazy var ptr: UnsafePointer<Float> = { UnsafePointer(buffer.contents().bindMemory(to: Float.self, capacity: npix)) }()
    lazy var data: [Float] = { Array(UnsafeBufferPointer(start: ptr, count: npix)) }()
    lazy var idx: UnsafeBufferPointer<Int32> = { indexed = true; return makeidx() }()
    
    // initialize map from buffer
    init(nside: Int, buffer: MTLBuffer, min: Double, max: Double) {
        self.nside = nside
        self.buffer = buffer
        
        self.min = min
        self.max = max
    }
    
    // map copy
    var copy: Self { Self(nside: nside, buffer: buffer.copy, min: min, max: max) }
    
    // clean up on deinitialization
    private var indexed = false
    deinit { if indexed { idx.deallocate() } }
    
    // index map (i.e. compute CDF)
    func index() { cdf = makecdf(intervals: 1<<12) }
}

// encapsulates map data, buffers, textures, and metadata
final class MapData: Identifiable, ObservableObject {
    // unique map id
    let id = UUID()
    
    // file metadata
    let file: String
    let info: String
    let card: Cards
    
    // map metadata
    let name: String
    let unit: String
    let channel: Int
    
    // map data and caches
    let data: Map
    var ranked: CpuMap? = nil
    var buffer: GpuMap? = nil
    
    // analysis state
    var analyzed = false
    
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
    init(file: String, info: String, parsed: Cards, name: String, unit: String, channel: Int, data: Map, ranked: CpuMap? = nil) {
        self.file = file; self.info = info; self.card = parsed
        self.name = name; self.unit = unit; self.channel = channel
        self.data = data; self.ranked = ranked
        
        // maybe we should always allocate mipmaps?
        self.texture = HPXTexture(nside: data.nside, mipmapped: AntiAliasing.value != .none)
    }
    
    // map duplicate copying or sharing data
    var copy: Self { Self(file: file, info: info, parsed: card, name: name, unit: unit, channel: channel, data: data.copy) }
    var snapshot: Self { Self(file: file, info: info, parsed: card, name: transform.annotate(name), unit: unit, channel: channel, data: available.copy) }
    var duplicate: Self { Self(file: file, info: info, parsed: card, name: name, unit: unit, channel: channel, data: data, ranked: ranked) }
    
    // signal that map state changed
    func refresh() { self.objectWillChange.send() }
}

extension MapData: Hashable, Equatable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: MapData, b: MapData) -> Bool { a.id == b.id }
}
