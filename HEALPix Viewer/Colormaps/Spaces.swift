//
//  Spaces.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-18.
//

import SwiftUI

// sRGB transfer curves
func srgb2lin(_ x: Double) -> Double { return x <= 0.04045 ? x/12.92 : pow((x+0.055)/1.055, 2.4) }
func lin2srgb(_ x: Double) -> Double { return x <= 0.04045/12.92 ? 12.92*x : 1.055*pow(x, 1.0/2.4) - 0.055 }

// HLG transfer curves
func lin2hlg(_ x: Double) -> Double {
    let a = 0.17883277, b = 1.0 - 4.0*a, c = 0.5 - a*log(4.0*a)
    return x <= 1.0/12.0 ? sqrt(3.0*x) : a*log(12.0*x-b) + c
}

func hlg2lin(_ x: Double) -> Double {
    let a = 0.17883277, b = 1.0 - 4.0*a, c = 0.5 - a*log(4.0*a)
    return x <= 0.5 ? x*x/3.0 : (exp((x-c)/a)+b)/12.0
}

// okLab

// color components extensions
extension Color {
    static var disabled: Color { return Color(NSColor.disabledControlTextColor) }
    
    var components: SIMD4<Float> {
        guard let color = NSColor(self).usingColorSpace(NSColorSpace.deviceRGB) else { return SIMD4<Float>(0.0) }
        let r = color.redComponent, g = color.greenComponent, b = color.blueComponent, a = color.alphaComponent
        
        return SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> { SIMD3<Scalar>(self.x, self.y, self.z) }
}
