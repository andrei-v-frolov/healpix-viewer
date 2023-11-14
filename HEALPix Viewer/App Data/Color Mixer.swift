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
        // color space primaries (okLab or linear sRGB, no transparency support)
        let lab = self.lab, gamma = double4((lab ? 3.0 : 1.0) * exp2(midtone))
        let black = (lab ? black.okLab : pow(black.sRGB, gamma))
        let white = (lab ? white.okLab : pow(white.sRGB, gamma)) - black
        let r = (lab ? r.okLab : pow(r.sRGB, gamma)) - black
        let g = (lab ? g.okLab : pow(g.sRGB, gamma)) - black
        let b = (lab ? b.okLab : pow(b.sRGB, gamma)) - black
        
        // color mixing matrix (optionally enforcing r+g+b = white)
        let q = double3x3(r.xyz, g.xyz, b.xyz).inverse * white.xyz
        return (mode != .add) ? double4x4(q.x*r, q.y*g, q.z*b, black) : double4x4(r,g,b,black)
    }
    
    // power law correction to be applied to the mix
    var gamma: double4 { double4((lab ? 1.0/3.0 : 1.0) * exp2(-midtone)) }
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
