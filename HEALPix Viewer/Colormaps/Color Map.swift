//
//  Colormap.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import SwiftUI
import MetalKit

final class ColorMap {
    let lut: [SIMD4<Float>]
    let texture: MTLTexture
    
    // singleton colormaps
    static let planck = ColorMap(lut: Planck_Parchment_LUT)
    static let freq = ColorMap(lut: Planck_FreqMap_LUT)
    static let diff = ColorMap(lut: Python_Difference_LUT)
    static let cmb = ColorMap(lut: HEALPix_CMB_LUT)
    static let grey = ColorMap(lut: HEALPix_Grey_LUT)
    static let hot = ColorMap(lut: HEALPix_Hot_LUT)
    static let cold = ColorMap(lut: HEALPix_Cold_LUT)
    static let lime = ColorMap(lut: HEALPix_Lime_LUT)
    static let GRV = ColorMap(lut: HEALPix_GRV_LUT)
    static let BGRY = ColorMap(lut: HEALPix_BGRY_LUT)
    
    // Metal texture representing colormap
    static func render(lut: [SIMD4<Float>]) -> MTLTexture {
        // texture format
        let width = lut.count, size = MemoryLayout<SIMD4<Float>>.size * width
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba32Float, width: width, height: 1, mipmapped: false)
        
        desc.textureType = MTLTextureType.type1D
        desc.usage = MTLTextureUsage.shaderRead
        
        // initialize compute pipeline
        guard let texture = metal.device.makeTexture(descriptor: desc)
              else { fatalError("Could not allocate color map texture") }
        
        // load texture contents
        lut.withUnsafeBytes { data in texture.replace(region: MTLRegionMake1D(0, width), mipmapLevel: 0, withBytes: data.baseAddress!, bytesPerRow: size) }
        
        return texture
    }
    
    // initialize colormap from LUT
    init(lut: [SIMD4<Float>]) {
        self.lut = lut; self.texture = ColorMap.render(lut: lut)
    }
    
    // initialize colormap from gradient
    init(gradient: ColorGradient) {
        self.lut = gradient.lut(1024); self.texture = ColorMap.render(lut: lut)
    }
    
    // initialize colormap from color list
    init?(colors: [Color]) {
        guard let gradient = ColorGradient(name: "gradient", colors) else { return nil }
        self.lut = gradient.lut(1024); self.texture = ColorMap.render(lut: lut)
    }
    
    subscript(index: Int) -> Color {
        let c = lut[index]
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z), opacity: Double(c.w))
    }
    
    var min: Color { return self[0] }
    var max: Color { return self[lut.count-1] }
}
