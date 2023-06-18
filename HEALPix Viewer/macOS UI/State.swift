//
//  State.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-17.
//

import SwiftUI

// viewpoint state
struct Viewpoint: Equatable, Codable {
    var orientation: Orientation = .defaultValue
    var lat: Double = 0.0
    var lon: Double = 0.0
    var az: Double = 0.0
}

// color palette state
struct Palette: Equatable, Codable {
    var scheme: ColorScheme = .defaultValue {
        didSet { min = scheme.colormap.min; max = scheme.colormap.max }
    }
    var min: Color = ColorScheme.defaultValue.colormap.min
    var max: Color = ColorScheme.defaultValue.colormap.max
    var nan: Color = .gray
    var bg: Color = .clear
}

// data transform state
struct Transform: Equatable, Codable {
    var f: Function = .defaultValue
    var mu: Double = 0.0
    var sigma: Double = 0.0
    
    func eval(_ x: Double) -> Double { return f.eval(x, mu: mu, sigma: sigma) }
    
    static func == (a: Self, b: Self) -> Bool {
        return (a.f == b.f) &&
               (a.f.mu ? a.mu == b.mu : true) &&
               (a.f.sigma ? a.sigma == b.sigma : true)
    }
}

// data range state
struct Bounds: Equatable, Codable {
    var mode: BoundsModifier = .defaultValue
    var min: Double = 0.0
    var max: Double = 0.0
}

// lighting state
struct Light: Equatable, Codable {
    var lat: Double = 45.0
    var lon: Double = -90.0
    var amt: Double =  60.0
}

// map view state
struct ViewState: Equatable, Codable {
    var projection = Projection.defaultValue
    var view = Viewpoint()
    var palette = Palette()
    var transform = Transform()
    var range = Bounds()
    var light = Light()
}

// cursor state
struct Cursor {
    var hover: Bool = false
    var lat: Double = 0.0
    var lon: Double = 0.0
    var pix: Int = 0
    var val: Double = 0.0
}
