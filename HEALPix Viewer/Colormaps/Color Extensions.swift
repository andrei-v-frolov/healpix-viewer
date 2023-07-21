//
//  Color Extensions.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-20.
//

import SwiftUI
import MetalKit

// color encoded as string value
extension Color: RawRepresentable, Codable {
    static var disabled: Color { return Color(NSColor.disabledControlTextColor) }
    
    public init(rawValue: String) { self = Self(name: rawValue) ?? .defaultValue }
    
    public init(hex i: Int) {
        self = Color(.sRGB,
            red: Double((i >> 24) & 0xFF)/255.0,
          green: Double((i >> 16) & 0xFF)/255.0,
           blue: Double((i >> 8)  & 0xFF)/255.0,
        opacity: Double(i & 0xFF)/255.0)
    }
    
    public init?(hexValue: String) {
        guard let i = Int(hexValue.dropFirst(hexValue.first == "#" ? 1 : 0), radix: 16) else { return nil }
        self = Self(hex: i)
    }
    
    public init?(name: String) {
        switch name.lowercased() {
            // named colors
            case "black":   self = .black
            case "blue":    self = .blue
            case "brown":   self = .brown
            case "clear":   self = .clear
            case "cyan":    self = .cyan
            case "gray":    self = .gray
            case "grey":    self = .gray
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
            
            // CSS or device RGBA color
            default: if let color = Self(hexValue: color_names_lut[name.lowercased()] ?? name) { self = color } else { return nil }
        }
    }
    
    public var hex: Int {
        let rgba = SIMD4<Int>(clamp(self.sRGB, min: 0.0, max: 1.0) * 255.0)
        return (rgba[0] << 24) | (rgba[1] << 16) | (rgba[2] << 8) | rgba[3]
    }
    
    public var hexValue: String { return String(format:"#%08X", hex) }
    
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
            
            // CSS or device RGBA color
            default: let value = hexValue; return color_values_lut[value] ?? value
        }
    }
}

// color formatter for text input
class ColorFormatter: Formatter {
    override func string(for object: Any?) -> String? {
        guard let color = object as? Color else { return nil }
        return color.hexValue
    }
    
    override func getObjectValue(_ object: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard let color = Color(name: string) ?? Color(hexValue: string) else { return false }
        object?.pointee = color as AnyObject; return true
    }
}
