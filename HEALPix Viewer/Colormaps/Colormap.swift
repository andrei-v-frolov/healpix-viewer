//
//  Colormap.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import SwiftUI
import MetalKit

struct Colormap {
    let lut: [SIMD4<Float>]
    
    // singleton colormaps
    static let planck = Colormap(lut: Planck_Parchment_LUT)
    static let freq = Colormap(lut: Planck_FreqMap_LUT)
    static let cmb = Colormap(lut: HEALPix_CMB_LUT)
    static let grey = Colormap(lut: HEALPix_Grey_LUT)
    static let hot = Colormap(lut: HEALPix_Hot_LUT)
    static let cold = Colormap(lut: HEALPix_Cold_LUT)
    static let GRV = Colormap(lut: HEALPix_GRV_LUT)
    static let BGRY = Colormap(lut: HEALPix_BGRY_LUT)
    
    // initialize colormap from LUT
    init(lut: [SIMD4<Float>]) {
        self.lut = lut
    }
    
    subscript(index: Int) -> Color {
        let c = lut[index]
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z), opacity: Double(c.w))
    }
    
    var min: Color { return self[0] }
    var max: Color { return self[lut.count-1] }
}

extension Color {
    var components: SIMD4<Float> {
        guard let color = NSColor(self).usingColorSpace(NSColorSpace.deviceRGB) else { return SIMD4<Float>(0.0) }
        let r = color.redComponent, g = color.greenComponent, b = color.blueComponent, a = color.alphaComponent
        
        return SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
    }
}
