//
//  State.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-17.
//

import SwiftUI

// convenience wrapper for tracking viewpoint changes
struct Viewpoint: Equatable {
    let latitude: Double
    let longitude: Double
    let azimuth: Double
}

// color palette state
struct Palette: Equatable {
    var scheme: ColorScheme = .defaultValue {
        didSet { min = scheme.colormap.min; max = scheme.colormap.max }
    }
    var min: Color = ColorScheme.defaultValue.colormap.min
    var max: Color = ColorScheme.defaultValue.colormap.max
    var nan: Color = .gray
    var bg: Color = .clear
}

// convenience wrapper for tracking range changes
struct Bounds: Equatable {
    let min: Double
    let max: Double
}

// convenience wrapper for tracking transform changes
struct Transform: Equatable {
    let transform: DataTransform
    let mu: Double
    let sigma: Double
    
    static func == (a: Self, b: Self) -> Bool {
        return (a.transform == b.transform) &&
               (a.transform.mu ? a.mu == b.mu : true) &&
               (a.transform.sigma ? a.sigma == b.sigma : true)
    }
}

struct Lighting {
    var enabled: Bool
    var lat: Double
    var lon: Double
    var amt: Double
}

struct Cursor {
    var hover: Bool
    var lat: Double
    var lon: Double
    var pix: Int
    var val: Double
}
