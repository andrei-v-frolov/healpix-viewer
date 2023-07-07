//
//  Preferences.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-12.
//

import SwiftUI
import MetalKit
import UniformTypeIdentifiers

// settings - appearance
let animateKey = "animate"
let lightingKey = "lighting"
let viewFromInsideKey = "viewFromInside"

// settings - behavior
let keepStateKey = "keepStateMask"
let copyStateKey = "copyStateMask"

// settings - export
let dragSettingsKey = "drag"
let exportSettingsKey = "export"
let annotationFontKey = "annotationFont"
let annotationColorKey = "annotationColor"

// settings - view menu
let cursorKey = "cursor"
let showColorBarKey = "showColorBar"

// application appearance
enum Appearance: String, CaseIterable, Codable, Preference {
    case dark = "Dark Mode"
    case light = "Light Mode"
    case system = "System Mode"
    
    // default value
    static let key = "appearance"
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

// map thumbnails
enum Thumbnails: String, CaseIterable, Codable, Preference {
    case none = "None"
    case left = "Left Side"
    case right = "Right Side"
    case large = "Large"
    
    // default value
    static let key = "thumbnails"
    static let defaultValue: Self = .large
}

// GPU selection
struct PreferredGPU: Hashable, CaseIterable, Codable {
    var prefer: GpuType = .system
    var named: String? = nil
    
    enum GpuType: String, Codable {
        case system = "Default"
        case integrated = "Integrated"
        case discrete = "Discrete"
        case external = "External"
        case specific = "Specific"
        
        static let kinds: [Self] = [.integrated, .discrete, .external]
    }
    
    // collections
    static let system = Self()
    static let profiled: [Self] = GpuType.kinds.map { Self(prefer: $0) }
    static var attached: [Self] { MTLCopyAllDevices().map { Self(prefer: .specific, named: $0.name) } }
    static var allCases: [Self] { [system] + profiled + attached }
    
    // default value
    static let key = "gpu"
    static let defaultValue = Self()
    
    // find preferred GPU
    var device: MTLDevice? {
        let system = MTLCreateSystemDefaultDevice()
        let devices = MTLCopyAllDevices()
        
        switch prefer {
            case .system:       return system
            case .integrated:   return devices.first(where: { !$0.isRemovable &&  $0.isLowPower }) ?? system
            case .discrete:     return devices.first(where: { !$0.isRemovable && !$0.isLowPower }) ?? system
            case .external:     return devices.first(where: { $0.isRemovable }) ?? system
            case .specific:     guard let name = named else { return system }
                                return devices.first(where: { $0.name.contains(name) }) ?? system
        }
    }
}

extension PreferredGPU: RawRepresentable, Preference {
    init(rawValue name: String) {
        switch name {
            case GpuType.system.rawValue: self = PreferredGPU.system
            case GpuType.integrated.rawValue: self = PreferredGPU(prefer: .integrated)
            case GpuType.discrete.rawValue: self = PreferredGPU(prefer: .discrete)
            case GpuType.external.rawValue: self = PreferredGPU(prefer: .external)
            default: self = PreferredGPU(prefer: .specific, named: name)
        }
    }
    
    var rawValue: String { prefer == .specific ? (named ?? GpuType.system.rawValue) : prefer.rawValue }
}

// rendering precision
enum TextureFormat: String, CaseIterable, Codable, Preference {
    case uint8 = "8-bit integer"
    case uint10 = "10-bit integer"
    case uint16 = "16-bit integer"
    case float16 = "16-bit float"
    case float32 = "32-bit float"
    
    // default value
    static let key = "pixel"
    static let defaultValue: Self = .uint10
    
    // backing texture format
    var pixel: MTLPixelFormat {
        switch self {
            case .uint8: return .rgba8Unorm
            case .uint10: return .rgb10a2Unorm
            case .uint16: return .rgba16Unorm
            case .float16: return .rgba16Float
            case .float32: return .rgba32Float
        }
    }
}

// antialiasing strategy
enum AntiAliasing: String, CaseIterable, Codable, Preference {
    case none = "nearest neighbour"
    case less = "downsample (less)"
    case more = "downsample (more)"
    
    // default value
    static let key = "antialiasing"
    static let defaultValue: Self = .more
}

// proxy map size
enum ProxySize: String, CaseIterable, Codable, Preference {
    case none = "None"
    
    // default value
    static let key = "proxy"
    static let defaultValue: Self = .none
}

// output image format
enum ImageFormat: String, CaseIterable, Codable, Preference {
    case gif = "GIF"
    case png = "PNG"
    case heif = "HEIF"
    case tiff = "TIFF"
    
    // default value
    static let key = "format"
    static let defaultValue: Self = .png
    
    // associated file type
    var type: UTType {
        switch self {
            case .gif: return .gif
            case .png: return .png
            case .heif: return .heif
            case .tiff: return .tiff
        }
    }
    
    // backing texture format
    var pixel: MTLPixelFormat {
        switch self {
            case .tiff: return .rgba16Unorm
            default:    return .rgba8Unorm
        }
    }
}

// exported file size preference
enum PreferredSize: String, CaseIterable, Codable, Preference {
    case specificWidth = "Image width"
    case specificHeight = "Image height"
    case width = "View width"
    case width2 = "View width x2"
    case width4 = "View width x4"
    case height = "View height"
    case height2 = "View height x2"
    case height4 = "View height x4"
    
    // default value
    static let key = "size"
    static let defaultValue: Self = .specificWidth
    
    // collections
    static let widths: [Self] = [.width, .width2, .width4]
    static let heights: [Self] = [.height, .height2, .height4]
    static let specified: [Self] = [.specificWidth, .specificHeight]
    
    // need specific dimension?
    var specific: Bool { Self.specified.contains(self) }
}

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
    case hammer = "Hammer"
    case lambert = "Lambert"
    case isometric = "Isometric"
    case gnomonic = "Gnomonic"
    case mercator = "Mercator"
    case cylindrical = "Plate Carrée"
    case werner = "Werner"
    
    // default value
    static let key = "projection"
    static let defaultValue: Self = .mollweide
    
    // projection bounds
    var extent: (x: Double, y: Double) {
        switch self {
            case .mollweide:            return (2,1)
            case .hammer:               return (sqrt(8.0),sqrt(2.0))
            case .lambert, .gnomonic:   return (2,2)
            case .mercator:             return (Double.pi,2)
            case .cylindrical:          return (Double.pi,Double.pi/2.0)
            case .werner:               return (2.021610497,2.029609241)
            default:                    return (1,1)
        }
    }
    
    // recommended aspect ratio
    func height(width: Double) -> Double { let (x,y) = extent; return y*width/x }
    func width(height: Double) -> Double { let (x,y) = extent; return x*height/y }
    
    // projection out of bounds
    static let outOfBounds = float3(0)
    
    // transform projection plane coordinates to a vector on a unit sphere
    func xyz(x: Double, y: Double) -> float3 {
        let pi = Double.pi, halfpi = Double.pi/2.0, OUT_OF_BOUNDS = Projection.outOfBounds
        switch self {
            case .mollweide:
                let psi = asin(y), phi = halfpi*x/cos(psi), theta = acos((2.0*psi + sin(2.0*psi))/pi)
                return (y < -1.0 || y > 1.0 || phi < -pi || phi > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .hammer:
                let p = x*x/4.0 + y*y, q = 1.0 - p/4.0, z = sqrt(q)
                let theta = acos(z*y), phi = 2.0*atan(z*x/(2.0*q-1.0)/2.0)
                return (p > 2.0) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .lambert:
                let q = 1.0 - (x*x + y*y)/4.0, z = sqrt(q)
                return (q < 0.0) ? OUT_OF_BOUNDS : float3(Float(2.0*q-1.0),Float(z*x),Float(z*y))
            case .isometric:
                let q = 1.0 - (x*x + y*y)
                return (q < 0.0) ? OUT_OF_BOUNDS : float3(Float(sqrt(q)),Float(x),Float(y))
            case .gnomonic:
                return normalize(float3(1.0,Float(x),Float(y)))
            case .mercator:
                let phi = x, theta = halfpi - atan(sinh(y))
                return (phi < -pi || phi > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .cylindrical:
                let phi = x, theta = halfpi - y
                return (phi < -pi || phi > pi || theta < 0.0 || theta > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
            case .werner:
                let y = y - 1.111983413, theta = sqrt(x*x+y*y), phi = theta/sin(theta)*atan2(x,-y)
                return (theta > pi || phi < -pi || phi > pi) ? OUT_OF_BOUNDS : ang2vec(theta,phi)
        }
    }
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
    case cmb = "HEALPix"
    case diff = "Difference"
    case freq = "Frequency Map"
    case grey = "Greyscale"
    case hot = "Hot"
    case cold = "Cold"
    case grv = "GRV"
    case bgry = "BGRY"
    
    // default value
    static let key = "colorScheme"
    static let defaultValue: Self = .planck
    
    // colormap singletons
    var colormap: Colormap {
        switch self {
            case .planck:   return Colormap.planck
            case .cmb:      return Colormap.cmb
            case .diff:     return Colormap.diff
            case .freq:     return Colormap.freq
            case .grey:     return Colormap.grey
            case .hot:      return Colormap.hot
            case .cold:     return Colormap.cold
            case .grv:      return Colormap.GRV
            case .bgry:     return Colormap.BGRY
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
}

// line convolution
enum LineConvolution: String, CaseIterable, Codable, Preference {
    case none = "None"
    case vector = "Vector Field"
    case polarization = "Polarization"
    
    // default value
    static let key = "convolution"
    static let defaultValue: Self = .none
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

// font encoded for @AppStorage
struct FontPreference: RawRepresentable, Preference {
    var nsFont: NSFont?
    var ctFont: CTFont? {
        get { nsFont as CTFont? }
        set { nsFont = newValue }
    }
    
    // initializer wrappers
    public init() { self.nsFont = nil }
    public init(nsFont: NSFont?) { self.nsFont = nsFont }
    public init(ctFont: CTFont?) { self.ctFont = ctFont }
    public init(rawValue: String) { self.nsFont = NSFont(name: rawValue, size: 0.0) }
    
    // default value
    static let key = "font"
    static let defaultValue = Self()
    public var rawValue: String { nsFont?.fontName ?? ""}
}

// color encoded for @AppStorage
extension Color: RawRepresentable, Codable, Preference {
    public init(rawValue: String) {
        switch rawValue.lowercased() {
            // named colors
            case "black":   self = .black
            case "blue":    self = .blue
            case "brown":   self = .brown
            case "clear":   self = .clear
            case "cyan":    self = .cyan
            case "gray":    self = .gray
            case "green":   self = .green
            case "indigo":  self = .indigo
            case "mint":    self = .mint
            case "orange":  self = .orange
            case "pink":    self = .pink
            case "purple":  self = .purple
            case "red":     self = .red
            case "teal":    self = .teal
            case "white":   self = .white
            case "yellow":  self = .yellow
            
            // semantic colors
            case "accent":      self = .accentColor
            case "primary":     self = .primary
            case "secondary":   self = .secondary
            case "disabled":    self = .disabled
            
            // device RGBA color
            default:
                guard let i = Int(rawValue, radix: 16) else { self = .defaultValue; return }
                self = Color(red: Double((i >> 24) & 0xFF)/255.0,
                           green: Double((i >> 16) & 0xFF)/255.0,
                            blue: Double((i >> 8)  & 0xFF)/255.0,
                         opacity: Double(i & 0xFF)/255.0)
        }
    }
    
    public var rawValue: String {
        switch self {
            // named colors
            case .black:    return "black"
            case .blue:     return "blue"
            case .brown:    return "brown"
            case .clear:    return "clear"
            case .cyan:     return "cyan"
            case .gray:     return "gray"
            case .green:    return "green"
            case .indigo:   return "indigo"
            case .mint:     return "mint"
            case .orange:   return "orange"
            case .pink:     return "pink"
            case .purple:   return "purple"
            case .red:      return "red"
            case .teal:     return "teal"
            case .white:    return "white"
            case .yellow:   return "yellow"
            
            // semantic colors
            case .accentColor:  return "accent"
            case .primary:      return "primary"
            case .secondary:    return "secondary"
            case .disabled:     return "disabled"
            
            // device RGBA color
            default:
            let rgba = SIMD4<Int>(clamp(self.components, min: 0.0, max: 1.0) * 255.0)
                return String(format:"%08X", (rgba[0] << 24) | (rgba[1] << 16) | (rgba[2] << 8) | rgba[3])
        }
    }
    
    // default value
    static let key = "color"
    static var defaultValue = Color.primary
}

// encapsulates @AppStorage preference properties
protocol Preference {
    static var key: String { get }
    static var value: Self { get }
    static var defaultValue: Self { get }
    
    init?(rawValue: String)
}

// default implementation of preference value access
extension Preference {
    static var value: Self {
        guard let raw = UserDefaults.standard.string(forKey: Self.key),
              let value = Self(rawValue: raw) else { return Self.defaultValue }
        
        return value
    }
}

// default implementation of JSON-encodable preference sets
protocol JsonRepresentable: RawRepresentable where RawValue == String {}

extension JsonRepresentable where Self: Codable {
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = value
    }
    
    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let value = String(data: data, encoding: .utf8) else { return "" }
        return value
    }
}
