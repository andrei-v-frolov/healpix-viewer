//
//  Colormap.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import Foundation
import MetalKit

struct Colormap {
    let lut: [SIMD4<Float>]
    
    init(lut: [SIMD4<Float>]) {
        self.lut = lut
    }
}
