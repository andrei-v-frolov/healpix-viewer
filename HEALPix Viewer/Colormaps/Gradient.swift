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
    
    // need at least two colors to make a gradient
    init?(name: String, _ colors: [Color]) {
        guard (colors.count > 1) else { return nil }
        self.name = name; self.colors = colors
    }
    
    // generate LUT by linear interpolation in okLab space
    func lut(_ n: Int) -> [SIMD4<Float>] {
        let lab = colors.map{ $0.okLab }
        var lut = [SIMD4<Float>](repeating: SIMD4<Float>(0.0), count: n)
        
        for i in 0..<n {
            let x = Double(i*(colors.count-1))/Double(n-1)
            let k = max(min(Int(floor(x)), colors.count-2), 0), q = x - Double(k)
            let mix = (1.0-q)*lab[k] + q*lab[k+1]
            
            lut[i] = SIMD4<Float>(SIMD4<Double>(ok2srgb(mix.xyz), mix.w))
        }
        
        return lut
    }
    
    // convenience wrapper
    func colormap(_ n: Int) -> ColorMap { ColorMap(lut: lut(n)) }
    
    // default value
    static let key = "gradient"
    static let defaultValue = Self(name: "New Gradient", [Color.blue, Color.white, Color.red])!
}

extension ColorGradient: JsonRepresentable {
    enum CodingKeys: String, CodingKey { case name, gradient }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        colors = try container.decode([Color].self, forKey: .gradient)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(colors, forKey: .gradient)
    }
}
