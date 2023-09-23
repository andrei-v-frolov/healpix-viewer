//
//  Color Spaces.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-18.
//

import SwiftUI
import MetalKit

// sRGB transfer curves
func srgb2lin(_ x: Double) -> Double { return x <= 0.04045 ? x/12.92 : pow((x+0.055)/1.055, 2.4) }
func lin2srgb(_ x: Double) -> Double { return x <= 0.04045/12.92 ? 12.92*x : 1.055*pow(x, 1.0/2.4) - 0.055 }

// HLG transfer curves
func lin2hlg(_ x: Double) -> Double {
    let a = 0.178832772656949765627521311568605
    let b = 1.0 - 4.0*a, c = 0.5 - a*log(4.0*a)
    return x <= 1.0/12.0 ? sqrt(3.0*x) : a*log(12.0*x-b) + c
}

func hlg2lin(_ x: Double) -> Double {
    let a = 0.178832772656949765627521311568605
    let b = 1.0 - 4.0*a, c = 0.5 - a*log(4.0*a)
    return x <= 0.5 ? x*x/3.0 : (exp((x-c)/a)+b)/12.0
}

// sRGB primaries to XYZ under D65 illuminant
let sRGB2XYZ_D65 = double3x3(
    SIMD3<Double>(0.4124,0.2126,0.0193),
    SIMD3<Double>(0.3576,0.7152,0.1192),
    SIMD3<Double>(0.1805,0.0722,0.9505)
)

// okLab space [https://bottosson.github.io/posts/oklab/]
let okLab_M1 = double3x3(
    SIMD3<Double>(+0.8189330101,+0.0329845436,+0.0482003018),
    SIMD3<Double>(+0.3618667424,+0.9293118715,+0.2643662691),
    SIMD3<Double>(-0.1288597137,+0.0361456387,+0.6338517070)
)

let okLab_M2 = double3x3(
    SIMD3<Double>(+0.2104542553,+1.9779984951,+0.0259040371),
    SIMD3<Double>(+0.7936177850,-2.4285922050,+0.7827717662),
    SIMD3<Double>(-0.0040720468,+0.4505937099,-0.8086757660)
)

func lrgb2ok(_ rgb: SIMD3<Double>) -> SIMD3<Double> {
    return okLab_M2*pow((okLab_M1*sRGB2XYZ_D65)*rgb, SIMD3<Double>(1.0/3.0))
}

func ok2lrgb(_ lab: SIMD3<Double>) -> SIMD3<Double> {
    return (okLab_M1*sRGB2XYZ_D65).inverse*pow(okLab_M2.inverse*lab, SIMD3<Double>(3.0))
}

func srgb2ok(_ rgb: SIMD3<Double>) -> SIMD3<Double> {
    return lrgb2ok(SIMD3<Double>(srgb2lin(rgb.x),srgb2lin(rgb.y),srgb2lin(rgb.z)))
}

func ok2srgb(_ lab: SIMD3<Double>) -> SIMD3<Double> {
    let rgb = ok2lrgb(lab); return SIMD3<Double>(lin2srgb(rgb.x),lin2srgb(rgb.y),lin2srgb(rgb.z))
}

// color components extensions
extension Color {
    // SIMD4 components in (pre-multiplied) device space
    var components: SIMD4<Float> {
        guard let color = NSColor(self).usingColorSpace(NSColorSpace.deviceRGB) else { return SIMD4<Float>(0.0) }
        let r = color.redComponent, g = color.greenComponent, b = color.blueComponent, a = color.alphaComponent
        
        return SIMD4<Float>(Float(a*r), Float(a*g), Float(a*b), Float(a))
    }
    
    // SIMD4 components in sRGB space
    var sRGB: SIMD4<Double> {
        guard let color = NSColor(self).usingColorSpace(NSColorSpace.sRGB) else { return SIMD4<Double>(0.0) }
        return SIMD4<Double>(color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
    }
    
    init(sRGB rgba: SIMD4<Double>) {
        self = Self(.sRGB, red: rgba.x, green: rgba.y, blue: rgba.z, opacity: rgba.w)
    }
    
    // SIMD4 components in okLab space
    var okLab: SIMD4<Double> {
        guard let color = NSColor(self).usingColorSpace(NSColorSpace.sRGB) else { return SIMD4<Double>(0.0) }
        let lab = srgb2ok(SIMD3<Double>(color.redComponent, color.greenComponent, color.blueComponent))
        
        return SIMD4<Double>(lab.x, lab.y, lab.z, color.alphaComponent)
    }
    
    init(okLab lab: SIMD4<Double>) {
        self = Self(l: lab.x, a: lab.y, b: lab.z, alpha: lab.w)
    }
    
    init(l: Double, a: Double, b: Double, alpha: Double = 1.0) {
        let rgb = ok2srgb(SIMD3<Double>(l,a,b))
        self = Self(.sRGB, red: rgb.x, green: rgb.y, blue: rgb.z, opacity: alpha)
    }
}

// color component manipulation
extension SIMD4 {
    var xyz: SIMD3<Scalar> { SIMD3<Scalar>(self.x, self.y, self.z) }
}

extension SIMD4 where Scalar: FloatingPoint {
    var premultiply: SIMD4<Scalar> { SIMD4<Scalar>(self.x*self.w, self.y*self.w, self.z*self.w, self.w) }
    var  demultiply: SIMD4<Scalar> { (self.w != Scalar(0)) ? SIMD4<Scalar>(self.x/self.w, self.y/self.w, self.z/self.w, self.w) : SIMD4<Scalar>(0) }
}
