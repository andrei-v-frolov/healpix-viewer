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

// color bar state
struct ColorBar: Equatable, Codable {
    var palette = Palette()
    var range = Bounds()
    
    static func == (a: Self, b: Self) -> Bool {
        return (a.palette == b.palette) && (a.range.min == b.range.min) && (a.range.max == b.range.max)
    }
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
struct StateMask: Equatable, Codable {
    var projection = false
    var view = false
    var transform = true
    var palette = true
    var range = true
    var light = false
    
    static let keep = StateMask(rawValue: 0b011101)
    static let copy = StateMask(rawValue: 0b011100)
}

extension StateMask: RawRepresentable {
    public init(rawValue: Int) {
        projection = (rawValue & 0b000001) != 0
              view = (rawValue & 0b000010) != 0
         transform = (rawValue & 0b000100) != 0
           palette = (rawValue & 0b001000) != 0
             range = (rawValue & 0b010000) != 0
             light = (rawValue & 0b100000) != 0
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

// export state
struct Export: Equatable, Codable {
    var format: ImageFormat = .png
    var size: PreferredSize = .specificWidth
    var dimension: Int = 1920
    var oversampling: Int = 1
    var colorbar: Bool = false
    var range: Bool = false
    var annotation: Bool = false
    
    static let drag = Export(format: .png, size: .width2)
    static let save = Export(format: .png, oversampling: 2, colorbar: true, range: true, annotation: true)
}

extension Export: JsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case format, size, dimension, oversampling, colorbar, range, annotation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        format = try container.decode(ImageFormat.self, forKey: .format)
        size = try container.decode(PreferredSize.self, forKey: .size)
        dimension = try container.decode(Int.self, forKey: .dimension)
        oversampling = try container.decode(Int.self, forKey: .oversampling)
        colorbar = try container.decode(Bool.self, forKey: .colorbar)
        range = try container.decode(Bool.self, forKey: .range)
        annotation = try container.decode(Bool.self, forKey: .annotation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(format, forKey: .format)
        try container.encode(size, forKey: .size)
        try container.encode(dimension, forKey: .dimension)
        try container.encode(oversampling, forKey: .oversampling)
        try container.encode(colorbar, forKey: .colorbar)
        try container.encode(range, forKey: .range)
        try container.encode(annotation, forKey: .annotation)
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
