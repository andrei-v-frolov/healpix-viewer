//
//  Preferences.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-12.
//

import SwiftUI
import UniformTypeIdentifiers

// map view window ID
let mapWindowID = "map view"
let gradientWindowID = "gradient editor"

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

// settings - expressions
let nsideKey = "nside"

// user defaults not set in @AppStorage initializers
let defaults: [String: Any] = [
    animateKey: true,
    lightingKey: false,
    viewFromInsideKey: true,
    showColorBarKey: false,
    cursorKey: false
]

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
    case fit = "Fit view"
    case fit2 = "Fit view x2"
    case fit4 = "Fit view x4"
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
    static let fits: [Self] = [.fit, .fit2, .fit4]
    static let widths: [Self] = [.width, .width2, .width4]
    static let heights: [Self] = [.height, .height2, .height4]
    static let specified: [Self] = [.specificWidth, .specificHeight]
    
    // need specific dimension?
    var specific: Bool { Self.specified.contains(self) }
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

// color preference
extension Color: Preference {
    // default value
    static let key = "color"
    static let defaultValue = Color.primary
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
