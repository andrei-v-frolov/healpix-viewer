//
//  Map View.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-09-26.
//

import SwiftUI
import MetalKit

// data sources
enum DataSource: String, CaseIterable, Codable, Preference {
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
    static let key = "source"
    static let defaultValue: Self = .i
    
    // collections
    static let temperature: [Self] = [.i]
    static let polarization: [Self] = [.q, .u, .e, .b, .p]
    static let vector: [Self] = [.x, .y, .v]
}

// spherical projection
enum Projection: String, CaseIterable, Codable, Preference {
    case mollweide = "Mollweide"
    case aitoff = "Aitoff"
    case hammer = "Hammer"
    case lambert = "Lambert"
    case equidistant = "Equidistant"
    case orthographic = "Orthographic"
    case stereographic = "Stereographic"
    case gnomonic = "Gnomonic"
    case mercator = "Mercator"
    case cartesian = "Cartesian"
    case werner = "Werner"
    
    // default value
    static let key = "projection"
    static let defaultValue: Self = .mollweide
    
    // projection bounds
    var extent: (x: Double, y: Double) {
        switch self {
            case .mollweide:    return (2,1)
            case .aitoff,
                 .cartesian:    return (Double.pi,Double.pi/2.0)
            case .hammer:       return (sqrt(8.0),sqrt(2.0))
            case .equidistant:  return (Double.pi,Double.pi)
            case .lambert,
                 .stereographic,
                 .gnomonic:     return (2,2)
            case .mercator:     return (Double.pi,2)
            case .werner:       return (2.021610497,2.029609241)
            default:            return (1,1)
        }
    }
    
    // relative level of detail
    var lod: Double {
        switch self {
            case .mollweide,
                 .orthographic,
                 .stereographic,
                 .werner:       return 0.625
            case .aitoff,
                 .mercator:     return 0.875
            case .hammer,
                 .equidistant:  return 0.750
            case .lambert:      return 0.500
            case .gnomonic:     return 1.750
            default:            return 0.000
        }
    }
    
    // recommended aspect ratio
    func height(width: Double) -> Double { let (x,y) = extent; return y*width/x }
    func width(height: Double) -> Double { let (x,y) = extent; return x*height/y }
    
    // projection out of bounds
    static let outOfBounds = SIMD3<Double>.zero
    
    // spherical coordinates to unit vector
    func ang2vec(_ theta: Double, _ phi: Double) -> SIMD3<Double> {
        let z = cos(theta), r = sin(theta)
        return SIMD3<Double>(r*cos(phi), r*sin(phi), z)
    }
    
    // unit vector to spherical coordinates
    func vec2ang(_ v: SIMD3<Double>) -> SIMD2<Double> {
        return SIMD2<Double>(atan2(sqrt(v.x*v.x+v.y*v.y),v.z), atan2(v.y,v.x))
    }
    
    // transform projection plane coordinates to a vector on a unit sphere
    func xyz(x: Double, y: Double) -> SIMD3<Double> {
        let pi = Double.pi, halfpi = Double.pi/2.0, OUT_OF_BOUNDS = Self.outOfBounds
        switch self {
            case .mollweide:
                let psi = asin(y), phi = halfpi*x/cos(psi), theta = acos((2.0*psi + sin(2.0*psi))/pi)
                return (y < -1.0 || y > 1.0 || phi < -pi || phi > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .hammer:
                let p = x*x/4.0 + y*y, q = 1.0 - p/4.0, z = sqrt(q)
                let theta = acos(z*y), phi = 2.0*atan(z*x/(2.0*q-1.0)/2.0)
                return (p > 2.0) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .aitoff:
                let a = sqrt(x*x/4.0 + y*y), sinc = a > 0.0 ? sin(a)/a : 1.0
                let z = y*sinc, r = sqrt(1.0-z*z), phi = 2.0*asin(0.5*x*sinc/r)
                return (a > halfpi) ? OUT_OF_BOUNDS : SIMD3<Double>(r*cos(phi),r*sin(phi),z)
            case .lambert:
                let q = 1.0 - (x*x + y*y)/4.0, z = sqrt(q)
                return (q < 0.0) ? OUT_OF_BOUNDS : SIMD3<Double>(2.0*q-1.0,z*x,z*y)
            case .equidistant:
                let theta = sqrt(x*x + y*y), phi = atan2(x,y), v = ang2vec(theta,phi)
                return (theta > pi) ? OUT_OF_BOUNDS : SIMD3<Double>(v.z,v.y,v.x)
            case .orthographic:
                let q = 1.0 - (x*x + y*y)
                return (q < 0.0) ? OUT_OF_BOUNDS : SIMD3<Double>(sqrt(q),x,y)
            case .stereographic:
                return 4.0/(4.0+x*x+y*y) * SIMD3<Double>(2.0,x,y) - SIMD3<Double>(1,0,0)
            case .gnomonic:
                return normalize(SIMD3<Double>(1.0,x,y))
            case .mercator:
                let phi = x, theta = halfpi - atan(sinh(y))
                return (phi < -pi || phi > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .cartesian:
                let phi = x, theta = halfpi - y
                return (phi < -pi || phi > pi || theta < 0.0 || theta > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .werner:
                let y = y - 1.111983413, theta = sqrt(x*x+y*y), phi = theta/sin(theta)*atan2(x,-y)
                return (theta > pi || phi < -pi || phi > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
        }
    }
    
    /*
    // Jacobian of the projection onto spherical coordinates
    func jacobian(x: Double, y: Double, epsilon: Double = 1.0e-8) -> double2x2 {
        let dx = vec2ang(xyz(x: x+epsilon, y: y)) - vec2ang(xyz(x: x-epsilon, y: y))
        let dy = vec2ang(xyz(x: x, y: y+epsilon)) - vec2ang(xyz(x: x, y: y-epsilon))

        return double2x2(dx/(2.0*epsilon), dy/(2.0*epsilon))
    }
    
    // principal direction stretch factor
    func stretch(x: Double, y: Double) -> Double {
        let M = jacobian(x: x, y: y)
        let a = M[0,1], b = M[1,1], c = -M[0,0], d = -M[1,0]
        let phi = atan2(b-c,a+d), psi = atan2(b+c,a-d)
        let u = (a+d)/cos(phi), v = (d-a)/cos(psi)
        let p = (u+v)/2.0, q = (u-v)/2.0
        
        return -log2(min(abs(p),abs(q)))
    }
    
    // median level of detail over the full view
    func scan_lod(granularity n: Int = 1024, percentile f: Double = 0.75) {
        let (x,y) = extent, dx = max(x,y)/Double(n+1)
        let nx = Int(floor(x/dx)), ny = Int(floor(y/dx))
        let scale = log2(max(x,2.0*y)/Double.pi)
        
        var lod = [Double](); lod.reserveCapacity(4*n*n)
        
        for i in -nx...nx { let x = Double(i)*dx
        for j in -ny...ny { let y = Double(j)*dx
            if xyz(x: x, y: y) == Self.outOfBounds { continue }
            lod.append(stretch(x: x, y: y) - scale)
        } }
        
        lod.sort(); print(lod[Int(f*Double(lod.count))])
    }
    */
}

// orientation presets
enum Orientation: String, CaseIterable, Codable, Preference {
    case free = "As Specified"
    case equator = "Equator"
    case north = "North Pole"
    case south = "South Pole"
    case eclipticEquator = "Ecliptic"
    case eclipticNorth = "Ecliptic North"
    case eclipticSouth = "Ecliptic South"
    
    // default value
    static let key = "orientation"
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
enum ColorScheme: String, CaseIterable, Codable, Preference {
    case planck = "Planck"
    case rdbu = "Faded"
    case spectral = "Spectral"
    case cmb = "HEALPix"
    case seismic = "Seismic"
    case diff = "Difference"
    case freq = "Frequency"
    case grey = "Greyscale"
    case hot = "Hot"
    case cold = "Cold"
    case lime = "Lime"
    case viridis = "Viridis"
    case bgry = "BGRY"
    case grv = "GRV"
    
    // default value
    static let key = "colorScheme"
    static let defaultValue: Self = .planck
    
    // colormap singletons
    var colormap: ColorMap {
        switch self {
            case .planck:   return ColorMap.planck
            case .rdbu:     return ColorMap.RdBu
            case .spectral: return ColorMap.spectral
            case .cmb:      return ColorMap.cmb
            case .seismic:  return ColorMap.seismic
            case .diff:     return ColorMap.diff
            case .freq:     return ColorMap.freq
            case .grey:     return ColorMap.grey
            case .hot:      return ColorMap.hot
            case .cold:     return ColorMap.cold
            case .lime:     return ColorMap.lime
            case .viridis:  return ColorMap.viridis
            case .bgry:     return ColorMap.BGRY
            case .grv:      return ColorMap.GRV
        }
    }
}

// data transform
enum Function: String, CaseIterable, Codable, Preference {
    case none = "None"
    case log = "Log"
    case asinh = "Arcsinh"
    case atan = "Arctan"
    case tanh = "Tanh"
    case power = "Power Law"
    case exp = "Exponential"
    case equalize = "Equalized"
    case normalize = "Normalized"
    
    // default value
    static let key = "transform"
    static let defaultValue: Self = .none
    
    // collections
    static let flatten: [Self] = [.log, .asinh, .atan, .tanh]
    static let expand: [Self] = [.power, .exp]
    static let function: [Self] = flatten + expand
    static let cdf: [Self] = [.equalize, .normalize]
    
    // transform formula
    var formula: String {
        switch self {
            case .log:      return "ln[x-μ]"
            case .asinh:    return "asinh[(x-μ)/σ]"
            case .atan:     return "atan[(x-μ)/σ]"
            case .tanh:     return "tanh[(x-μ)/σ]"
            case .power:    return "±|x-μ|^σ"
            case .exp:      return "exp[(x-μ)/σ]"
            default: return rawValue
        }
    }
    
    // parameter needs
    var mu: Bool {
        switch self {
            case .log, .asinh, .atan, .tanh, .power, .exp: return true
            default: return false
        }
    }
    
    var sigma: Bool {
        switch self {
            case .asinh, .atan, .tanh, .power, .exp: return true
            default: return false
        }
    }
    
    // sigma range
    var range: ClosedRange<Double> {
        switch self {
            case .power:    return -2.00...2.00
            default:        return -10.0...10.0
        }
    }
    
    // evaluate transform
    func eval(_ x: Double, mu: Double = 0.0, sigma: Double = 0.0) -> Double {
        let sigma = Foundation.exp(sigma), epsilon = Double(Float.leastNormalMagnitude)
        
        switch self {
            case .log:      return Foundation.log(max(x-mu,epsilon))
            case .asinh:    return Foundation.asinh((x-mu)/sigma)
            case .atan:     return Foundation.atan((x-mu)/sigma)
            case .tanh:     return Foundation.tanh((x-mu)/sigma)
            case .power:    return copysign(pow(abs(x-mu),sigma),x-mu)
            case .exp:      return Foundation.exp((x-mu)/sigma)
            default:        return x
        }
    }
    
    // annotate transform
    func annotate(_ x: String, mu: Double = 0.0, sigma: Double = 0.0) -> String {
        let shifted = (mu > 0.0) ? "\(x)-\(mu)" : ((mu < 0.0) ? "\(x)+\(-mu)" : x)
        let scaled = (sigma == 0.0) ? shifted : ((mu != 0.0) ? "(\(shifted))/\(Foundation.exp(sigma))" : "\(x)/\(Foundation.exp(sigma))")
        
        switch self {
            case .none:     return x
            case .log:      return "ln[\(shifted)]"
            case .asinh:    return "asinh[\(scaled)]"
            case .atan:     return "atan[\(scaled)]"
            case .tanh:     return "tanh[\(scaled)]"
            case .power:    return (sigma == 0.0) ? shifted : "±|\(shifted)|^\(Foundation.exp(sigma))"
            case .exp:      return "exp[\(scaled)]"
            case .equalize: return "equalized[\(x)]"
            case .normalize: return "normalized[\(x)]"
        }
    }
}

// data bounds modifier
enum BoundsModifier: String, CaseIterable, Codable, Preference {
    case full = "Full"
    case symmetric = "Symmetric"
    case positive = "Positive"
    case negative = "Negative"
    
    // default value
    static let key = "bounds"
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
