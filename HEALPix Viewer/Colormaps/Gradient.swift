//
//  Gradient.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-18.
//

import SwiftUI
import MetalKit

struct ColorGradient: Equatable, Codable {
    var name: String
    var colors: [Color]
    
    // gradient modifiers
    var brightness: Double = 0.0
    var saturation: Double = 1.0
    var contrast: Double = 1.0
    
    // need at least two colors to make a gradient
    init?(_ name: String, colors: [Color], brightness: Double = 0.0, saturation: Double = 1.0, contrast: Double = 1.0) {
        guard (colors.count > 1) else { return nil }
        
        self.name = name
        self.colors = colors
        self.brightness = brightness
        self.saturation = saturation
        self.contrast = contrast
    }
    
    // generate LUT by linear interpolation in okLab space
    func lut(_ n: Int) -> [SIMD4<Float>] {
        let lab = colors.map { $0.okLab }
        let a = (lab.reduce(double4(0.0)){ $0+$1.premultiply }/Double(lab.count)).demultiply
        let b = exp2(brightness/3.0), c = exp2(brightness/4.0)*saturation
        let anchor = lab.map { v in double4(b*(a.x + contrast*(v.x-a.x)), c*v.y, c*v.z, v.w) }
        var lut = [SIMD4<Float>](repeating: SIMD4<Float>(0.0), count: n)
        
        for i in 0..<n {
            let x = Double(i*(colors.count-1))/Double(n-1)
            let k = max(min(Int(floor(x)), colors.count-2), 0), q = x - Double(k)
            let mix = (1.0-q)*anchor[k] + q*anchor[k+1]
            
            lut[i] = SIMD4<Float>(SIMD4<Double>(ok2srgb(mix.xyz), mix.w))
        }
        
        return lut
    }
    
    // convenience wrapper
    func colormap(_ n: Int) -> ColorMap { ColorMap(lut: lut(n)) }
    
    // default value
    static let defaultValue = Self("New Gradient", colors: [.blue, .white, .red])!
}

extension ColorGradient: JsonRepresentable {
    enum CodingKeys: String, CodingKey { case name, colors, brightness, saturation, contrast }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        colors = try container.decode([Color].self, forKey: .colors)
        brightness = (try? container.decode(Double.self, forKey: .brightness)) ?? 0.0
        saturation = (try? container.decode(Double.self, forKey: .saturation)) ?? 1.0
        contrast = (try? container.decode(Double.self, forKey: .contrast)) ?? 1.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(colors, forKey: .colors)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(saturation, forKey: .saturation)
        try container.encode(contrast, forKey: .contrast)
    }
}
