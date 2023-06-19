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
    var transform = Transform()
    var palette = Palette()
    var range = Bounds()
    var light = Light()
    
    mutating func update(_ state: ViewState, mask: StateMask) {
        if mask.projection { self.projection = state.projection }
        if mask.view { self.view = state.view }
        if mask.transform { self.transform = state.transform }
        if mask.palette { self.palette = state.palette }
        if mask.range { self.range = state.range }
        if mask.light { self.light = state.light }
    }
    
    func copy(_ state: ViewState, mask: StateMask) -> ViewState {
        return ViewState(
            projection: mask.projection ? state.projection : self.projection,
            view: mask.view ? state.view : self.view,
            transform: mask.transform ? state.transform : self.transform,
            palette: mask.palette ? state.palette : self.palette,
            range: mask.range ? state.range : self.range,
            light: mask.light ? state.light : self.light
        )
    }
}

// state changes mask
struct StateMask: RawRepresentable, Equatable, Codable {
    var projection = false
    var view = false
    var transform = true
    var palette = true
    var range = true
    var light = false
    
    public init() { }
    
    public init(rawValue: Int) {
        projection = (rawValue & 0b000001) != 0
              view = (rawValue & 0b000010) != 0
         transform = (rawValue & 0b000100) != 0
           palette = (rawValue & 0b001000) != 0
             range = (rawValue & 0b010000) != 0
            light  = (rawValue & 0b100000) != 0
    }
    
    public var rawValue: Int {
        return     (projection ? 0b000001 : 0) |
                         (view ? 0b000010 : 0) |
                    (transform ? 0b000100 : 0) |
                      (palette ? 0b001000 : 0) |
                        (range ? 0b010000 : 0) |
                        (light ? 0b100000 : 0)
    }
}

// cursor state
struct Cursor {
    var hover: Bool = false
    var lat: Double = 0.0
    var lon: Double = 0.0
    var pix: Int = 0
    var val: Double = 0.0
}
