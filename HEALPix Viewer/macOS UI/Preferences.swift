//
//  Preferences.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-12.
//

import SwiftUI

// boolean application storage keys
let showColorBarKey = "showColorBar"
let showDataBarKey = "showDataBar"
let lightingKey = "lighting"

// application appearance
enum Appearance: String, CaseIterable, Preference {
    case dark = "Dark Mode"
    case light = "Light Mode"
    case system = "System Mode"
    
    // default value
    static let appStorage = "appearance"
    static let defaultValue: Self = .system
    
    // associated value
    var appearance: NSAppearance? {
        switch self {
            case .dark: return NSAppearance(named: .darkAqua)
            case .light: return NSAppearance(named: .aqua)
            default: return nil
        }
    }
}

// scalar data sources
enum DataSource: String, CaseIterable, Preference {
    case i = "Temperature I"
    case q = "Polarization Q"
    case u = "Polarization U"
    case e = "Polarization E"
    case b = "Polarization B"
    case p = "Polarization P"
    case x = "Vector Field X"
    case y = "Vector Field Y"
    case v = "Vector Field V"
    
    // default value
    static let appStorage = "dataSource"
    static let defaultValue: Self = .i
    
    // collections
    static let temperature: [Self] = [.i]
    static let polarization: [Self] = [.q, .u, .e, .b, .p]
    static let vector: [Self] = [.x, .y, .v]
}

// line convolution direction to be applied
enum DataConvolution: String, CaseIterable, Preference {
    case none = "None"
    case polarization = "Polarization"
    case vector = "Vector Field"
    
    // default value
    static let appStorage = "convolution"
    static let defaultValue: Self = .none
}

// spherical projection to be used
enum Projection: String, CaseIterable, Preference {
    case mollweide = "Mollweide"
    case gnomonic = "Gnomonic"
    case lambert = "Lambert"
    case isometric = "Isometric"
    case mercator = "Mercator"
    case werner = "Werner"
    
    // default value
    static let appStorage = "projection"
    static let defaultValue: Self = .mollweide
    
    // projection bounds
    var extent: (x: Double, y: Double) {
        switch self {
            case .mollweide: return (2,1)
            case .lambert:   return (2,2)
            case .mercator:  return (Double.pi,2)
            case .werner:    return (2.021610497,2.029609241)
            default:         return (1,1)
        }
    }
}

// projection orientation lock
enum Orientation: String, CaseIterable, Preference {
    case free = "As Specified"
    case equator = "Equator"
    case north = "North Pole"
    case south = "South Pole"
    case eclipticEquator = "Ecliptic"
    case eclipticNorth = "Ecliptic North"
    case eclipticSouth = "Ecliptic South"
    
    // default value
    static let appStorage = "orientation"
    static let defaultValue: Self = .equator
    
    // collections
    static let galactic: [Self] = [.equator, .north, .south]
    static let ecliptic: [Self] = [.eclipticEquator, .eclipticNorth, .eclipticSouth]
    
    // predefined orientations
    var coords: (lat: Double, lon: Double, az: Double) {
        switch self {
            case .equator:          return (0,0,0)
            case .north:            return (90,0,0)
            case .south:            return (-90,0,0)
            case .eclipticEquator:  return (-60.18845577,96.33723581,0.040679)  // double check!!!
            case .eclipticNorth:    return (29.81163604,96.38395884,0.023278)   // double check!!!
            case .eclipticSouth:    return (-29.81126914,-83.615941,179.977140) // double check!!!
            default:                return (0,0,0)
        }
    }
}

// color scheme
enum ColorScheme: String, CaseIterable, Preference {
    case planck = "Planck"
    case cmb = "HEALPix CMB"
    case grey = "Greyscale"
    case hot = "Hot"
    case cold = "Cold"
    case freq = "Frequency Map"
    case grv = "GRV"
    case bgry = "BGRY"
    
    // default value
    static let appStorage = "colorScheme"
    static let defaultValue: Self = .planck
    
    // colormap singletons
    var colormap: Colormap {
        switch self {
            case .planck:   return Colormap.planck
            case .freq:     return Colormap.freq
            case .cmb:      return Colormap.cmb
            case .grey:     return Colormap.grey
            case .hot:      return Colormap.hot
            case .cold:     return Colormap.cold
            case .grv:      return Colormap.GRV
            case .bgry:     return Colormap.BGRY
            default:        return Colormap.cmb
        }
    }
}

// color scheme
enum DataTransform: String, CaseIterable, Preference {
    case linear = "Linear"
    case log = "Logarithmic"
    case asinh = "asinh scaling"
    case equalize = "Equalize"
    case normalize = "Normalize"
    
    // default value
    static let appStorage = "dataTransform"
    static let defaultValue: Self = .linear
}

// data bounds to be mapped to color bar
enum DataBounds: String, CaseIterable {
    case values = "Values"
    case percentile = "Percentile"
    
    // default value
    static let appStorage = "dataBounds"
    static let defaultValue: Self = .values
}

// data bounds modifier
enum BoundsModifier: String, CaseIterable, Preference {
    case full = "Full"
    case symmetric = "Symmetric"
    case positive = "Positive"
    case negative = "Negative"
    
    // default value
    static let appStorage = "boundsModifier"
    static let defaultValue: Self = .full
}

// encapsulates @AppStorage preference properties
protocol Preference {
    static var appStorage: String { get }
    static var defaultValue: Self { get }
    static var value: Self { get }
    
    init?(rawValue: String)
}

// default implementation of current value access
extension Preference {
    static var value: Self {
        guard let raw = UserDefaults.standard.string(forKey: Self.appStorage),
              let value = Self(rawValue: raw) else { return Self.defaultValue }
        
        return value
    }
}
