//
//  Preferences.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-12.
//

import SwiftUI

// boolean application storage keys
let viewFromInsideKey = "viewFromInside"
let showColorBarKey = "showColorBar"
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
    
    // recommended aspect ratio
    func height(width: Double) -> Double { let (x,y) = extent; return y*width/x }
    func width(height: Double) -> Double { let (x,y) = extent; return x*height/y }
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

// data transform
enum DataTransform: String, CaseIterable, Preference {
    case none = "None"
    case log = "Log"
    case asinh = "Arcsinh"
    case atan = "Arctan"
    case tanh = "Tanh"
    case equalize = "Equalized"
    case normalize = "Normalized"
    
    // default value
    static let appStorage = "dataTransform"
    static let defaultValue: Self = .none
    
    // collections
    static let flatten: [DataTransform] = [.log, .asinh, .atan, .tanh]
    static let expand: [DataTransform] = []
    static let function: [DataTransform] = flatten + expand
    static let cdf: [DataTransform] = [.equalize, .normalize]
    
    // transform formula
    var formula: String {
        switch self {
            case .log:      return "ln[x-μ]"
            case .asinh:    return "asinh[(x-μ)/σ]"
            case .atan:     return "atan[(x-μ)/σ]"
            case .tanh:     return "tanh[(x-μ)/σ]"
            default: return rawValue
        }
    }
    
    // parameter needs
    var mu: Bool {
        switch self {
            case .log, .asinh, .atan, .tanh: return true
            default: return false
        }
    }
    
    var sigma: Bool {
        switch self {
            case .asinh, .atan, .tanh: return true
            default: return false
        }
    }
    
    // functional transform
    func f(_ x: Double, mu: Double = 0.0, sigma: Double = 0.0) -> Double {
        let sigma = exp(sigma), epsilon = Double(Float.leastNormalMagnitude)
        
        switch self {
            case .log:      return Foundation.log(max(x-mu,epsilon))
            case .asinh:    return Foundation.asinh((x-mu)/sigma)
            case .atan:     return Foundation.atan((x-mu)/sigma)
            case .tanh:     return Foundation.tanh((x-mu)/sigma)
            default:        return x
        }
    }
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

// alignment tags
enum Anchor: Int, CaseIterable {
    case nw = 0b0000, n = 0b0001, ne = 0b0010
    case  w = 0b0100, c = 0b0101,  e = 0b0110
    case sw = 0b1000, s = 0b1001, se = 0b1010
    
    var halign: Double { Double((rawValue & 0b0011) - 1) }
    var valign: Double { Double((rawValue & 0b1100) >> 2 - 1) }
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
