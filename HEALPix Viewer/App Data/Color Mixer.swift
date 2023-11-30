//
//  Color Mixer.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-09-26.
//

import SwiftUI
import MetalKit

// color mixer primaries and attributes
struct Primaries: Equatable, Codable {
    var r = Color(red:1.0, green: 0.0, blue: 0.0, opacity: 1.0)
    var g = Color(red:0.0, green: 1.0, blue: 0.0, opacity: 1.0)
    var b = Color(red:0.0, green: 0.0, blue: 1.0, opacity: 1.0)
    var black = Color(red:0.0, green: 0.0, blue: 0.0, opacity: 1.0)
    var white = Color(red:1.0, green: 1.0, blue: 1.0, opacity: 1.0)
    var midtone = 0.0 // base gamma correction on log2 scale
    var mode = Mixing.defaultValue
    var gamut = Gamut.defaultValue
    var compress = false
    
    // blend in okLab?
    var lab: Bool { mode == .blend }
    
    // color mixing matrix
    var mixer: double4x4 {
        // color space primaries (okLab or linear sRGB, no transparency)
        let lab = self.lab, gamma = double3(exp2(midtone))
        let black = { lab ? srgb2ok($0) : $0 }(pow(black.sRGB.xyz, gamma))
        let white = { lab ? srgb2ok($0) : $0 }(pow(white.sRGB.xyz, gamma))
        let r = { lab ? srgb2ok($0) : $0 }(pow(r.sRGB.xyz, gamma))
        let g = { lab ? srgb2ok($0) : $0 }(pow(g.sRGB.xyz, gamma))
        let b = { lab ? srgb2ok($0) : $0 }(pow(b.sRGB.xyz, gamma))
        
        // color mixing matrix
        if (mode == .add) { return double4x4(double4(r,0), double4(g,0), double4(b,0), double4(black,1)) }
        
        // optionally scale (r+g+b) + black = white
        let q = double3x3(r,g,b).inverse * (white + 2.0*black)
        let x = q.x*r-black, y = q.y*g-black, z = q.z*b-black
        return double4x4(double4(x,0), double4(y,0), double4(z,0), double4(black,1))
    }
    
    // power law correction to be applied to the mix
    var gamma: double4 { double4(exp2(-midtone)/3.0) }
    
    // backing color space
    enum Space { case rgb, lab }
    var space: Space { mode == .blend ? .lab : .rgb }
    
    // Metal shader index
    struct Shader: Hashable { let space: Space, compress: Bool, gamut: Gamut }
    var shader: Shader { Shader(space: space, compress: compress, gamut: gamut) }
    
    // Metal shader variants
    static func shaders(kernel f: String) -> [Primaries.Shader: MetalKernel] { [
        Shader(space: .rgb, compress: false, gamut: .clip) : MetalKernel(kernel: "rgb\(f)_clip"),
        Shader(space: .rgb, compress: false, gamut: .film) : MetalKernel(kernel: "rgb\(f)_film"),
        Shader(space: .rgb, compress: false, gamut: .hlg)  : MetalKernel(kernel: "rgb\(f)_hlg"),
        Shader(space: .rgb, compress: false, gamut: .hdr)  : MetalKernel(kernel: "rgb\(f)_hdr"),
        Shader(space: .lab, compress: false, gamut: .clip) : MetalKernel(kernel: "lab\(f)_clip"),
        Shader(space: .lab, compress: false, gamut: .film) : MetalKernel(kernel: "lab\(f)_film"),
        Shader(space: .lab, compress: false, gamut: .hlg)  : MetalKernel(kernel: "lab\(f)_hlg"),
        Shader(space: .lab, compress: false, gamut: .hdr)  : MetalKernel(kernel: "lab\(f)_hdr"),
        Shader(space: .rgb, compress: true,  gamut: .clip) : MetalKernel(kernel: "crgb\(f)_clip"),
        Shader(space: .rgb, compress: true,  gamut: .film) : MetalKernel(kernel: "crgb\(f)_film"),
        Shader(space: .rgb, compress: true,  gamut: .hlg)  : MetalKernel(kernel: "crgb\(f)_hlg"),
        Shader(space: .rgb, compress: true,  gamut: .hdr)  : MetalKernel(kernel: "crgb\(f)_hdr"),
        Shader(space: .lab, compress: true,  gamut: .clip) : MetalKernel(kernel: "clab\(f)_clip"),
        Shader(space: .lab, compress: true,  gamut: .film) : MetalKernel(kernel: "clab\(f)_film"),
        Shader(space: .lab, compress: true,  gamut: .hlg)  : MetalKernel(kernel: "clab\(f)_hlg"),
        Shader(space: .lab, compress: true,  gamut: .hdr)  : MetalKernel(kernel: "clab\(f)_hdr")
    ] }
}

extension Primaries: JsonRepresentable, Preference {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, black, white, midtone, mode, gamut, compress
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        r = try container.decode(Color.self, forKey: .red)
        g = try container.decode(Color.self, forKey: .green)
        b = try container.decode(Color.self, forKey: .blue)
        black = try container.decode(Color.self, forKey: .black)
        white = try container.decode(Color.self, forKey: .white)
        midtone = try container.decode(Double.self, forKey: .midtone)
        mode = try container.decode(Mixing.self, forKey: .mode)
        gamut = try container.decode(Gamut.self, forKey: .gamut)
        compress = try container.decode(Bool.self, forKey: .compress)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(r, forKey: .red)
        try container.encode(g, forKey: .green)
        try container.encode(b, forKey: .blue)
        try container.encode(black, forKey: .black)
        try container.encode(white, forKey: .white)
        try container.encode(midtone, forKey: .midtone)
        try container.encode(mode, forKey: .mode)
        try container.encode(gamut, forKey: .gamut)
        try container.encode(compress, forKey: .compress)
    }
    
    // default value
    static let key = "primaries"
    static let defaultValue = Self()
}

// color mixing preference
enum Mixing: String, CaseIterable, Codable, Preference {
    case add = "Add"
    case mix = "Mix"
    case blend = "Blend"
    
    // help string
    var description: String {
        switch self {
            case .add:      return "Co-add RGB primaries as they are"
            case .mix:      return "Scale RGB primaries to achieve specified white point"
            case .blend:    return "Blend in perceptually uniform color space"
        }
    }
    
    // default value
    static let key = "mixing"
    static let defaultValue: Self = .blend
}

// gamut mapping preference
enum Gamut: String, CaseIterable, Codable, Preference {
    case clip = "Clip"
    case film = "Film"
    case hlg = "HLG"
    case hdr = "HDR"
    
    // help string
    var description: String {
        switch self {
            case .clip:     return "Clip colors to SDR gamut"
            case .film:     return "Map colors to SDR gamut using filmic curve"
            case .hlg:      return "Compress highlights using hybrid log-gamma"
            case .hdr:      return "Use full HDR gamut"
        }
    }
    
    // icons and labels
    var label: some View {
        switch self {
            case .clip:     return Label { Text(rawValue) } icon: { Curve.clip.frame(width: 20, height: 24) }
            case .film:     return Label { Text(rawValue) } icon: { Curve.film.frame(width: 20, height: 24) }
            case .hlg:      return Label { Text(rawValue) } icon: { Curve.hlg.frame(width: 20, height: 24) }
            case .hdr:      return Label { Text(rawValue) } icon: { Curve.hdr.frame(width: 20, height: 24) }
        }
    }
    
    // extended dynamic range?
    var extended: Bool {
        switch self {
            case .hlg, .hdr:    return true
            case .clip, .film:  return false
        }
    }
    
    // default value
    static let key = "gamut"
    static let defaultValue: Self = .hdr
}
