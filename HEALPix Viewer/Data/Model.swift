//
//  Model.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-08-07.
//

import SwiftUI

// frequency units
enum Frequency: String, CaseIterable {
    case MHz, GHz, THz
    
    // pivot frequency is 100GHz
    func pivot(_ f: Double) -> Double {
        switch self {
            case .MHz: return f/1.0e5
            case .GHz: return f/1.0e2
            case .THz: return f*1.0e1
        }
    }
    
    // convert to different units
    func convert(_ f: Double, to: Frequency) -> Double {
        let f = pivot(f); switch to {
            case .MHz: return f*1.0e5
            case .GHz: return f*1.0e2
            case .THz: return f/1.0e1
        }
    }
    
    // default value
    static let defaultValue: Self = .GHz
}

// radiance units
enum Radiance: Hashable, CaseIterable {
    enum Temperature: String, CaseIterable {
        case uK = "µK", mK, K
        
        // pivot temperature is 1K
        func pivot(_ t: Double) -> Double {
            switch self {
                case .K:  return t
                case .mK: return t/1.0e3
                case .uK: return t/1.0e6
            }
        }
        
        // convert to different units
        func convert(_ t: Double, to: Temperature) -> Double {
            let t = pivot(t); switch to {
                case .K:  return t
                case .mK: return t*1.0e3
                case .uK: return t*1.0e6
            }
        }
        
        // default value
        static let defaultValue: Self = .K
    }
    
    enum Flux: String, CaseIterable {
        case Jy = "Jy/sr", kJy = "kJy/sr", MJy = "MJy/sr", GJy = "GJy/sr"
        
        // pivot flux is GJy/sr
        func pivot(_ f: Double) -> Double {
            switch self {
                case .Jy:  return f/1.0e9
                case .kJy: return f/1.0e6
                case .MJy: return f/1.0e3
                case .GJy: return f
            }
        }
        
        // convert to different units
        func convert(_ f: Double, to: Flux) -> Double {
            let f = pivot(f); switch to {
                case .Jy:  return f*1.0e9
                case .kJy: return f*1.0e6
                case .MJy: return f*1.0e3
                case .GJy: return f
            }
        }
        
        // default value
        static let defaultValue: Self = .MJy
    }
    
    case rj(Temperature)    // Rayleigh-Jeans temperature
    case cmb(Temperature)   // black body temperature
    case flux(Flux)         // spectral irradiance
    
    // pivot temperatures (K)
    static let Tcmb: Double = 2.755
    static let T100: Double = 4.799243073
    static let TGJy: Double = 0.2590110327
    
    // Planck spectrum derivative
    func gamma(_ f: Double) -> Double {
        let nu = (Radiance.T100/Radiance.Tcmb) * f, mu = exp(nu)
        return nu*nu*mu/pow(mu-1.0,2)
    }
    
    // pivot flux unit is K_rj, pivot frequency is 100GHz
    func pivot(_ v: Double, f: Double = 1.0) -> Double {
        switch self {
            case .rj(let t):    return t.pivot(v)
            case .cmb(let t):   return t.pivot(v) * gamma(f)
            case .flux(let u):  return u.pivot(v) * (f*f) * Radiance.TGJy
        }
    }
    
    // convert to different units
    func convert(_ v: Double, to: Radiance, f: Double = 1.0) -> Double {
        let v = pivot(v, f: f); switch to {
            case .rj(let t):    return Temperature.K.convert(v, to: t)
            case .cmb(let t):   return Temperature.K.convert(v, to: t)/gamma(f)
            case .flux(let u):  return Flux.GJy.convert(v/Radiance.TGJy/(f*f), to: u)
        }
    }
    
    // text label
    var label: some View {
        switch self {
            case .rj(let t):    return Text(t.rawValue) + Text("RJ").font(.footnote)
            case .cmb(let t):   return Text(t.rawValue) + Text("CMB").font(.footnote)
            case .flux(let u):  return Text(u.rawValue)
        }
    }
    
    // collections
    static let CMB = Temperature.allCases.map { Self.cmb($0) }
    static let RJ = Temperature.allCases.map { Self.rj($0) }
    static let JY = Flux.allCases.map { Self.flux($0) }
    static let allCases = CMB + RJ + JY
    
    // default value
    static let defaultValue: Self = .cmb(.K)
}

// spectral model
enum Spectrum {
    case power(Double)
    case planck(Double)
    case mbb(Double,Double)
}
