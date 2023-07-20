//
//  Gradient.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-18.
//

import SwiftUI
import MetalKit

struct ColorGradient {
    // gradient color list
    var colors: [Color]
    
    // need at least two colors to make a gradient
    init?(_ colors: [Color]) {
        guard (colors.count > 1) else { return nil }
        self.colors = colors
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
}
