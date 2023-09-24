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
        let value = hexValue.dropFirst(hexValue.first == "#" ? 1 : 0)
        guard let i = Int(value, radix: 16) else { return nil }
        
        switch value.count {
            case 8: self = Self(hex: i)
            case 6: self = Self(hex: (i << 8) + 0xFF)
            default: return nil
        }
    }
    
    public init?(name: String) {
        let canonical = name.lowercased().filter{!$0.isWhitespace}
        
        if let color = named_color_lut[canonical] { self = color }
        else if let color = Self(hexValue: name) { self = color }
        else { return nil }
    }
    
    public var hex: Int {
        let rgba = SIMD4<Int>(floor(clamp(self.sRGB, min: 0.0, max: 1.0) * 255.0 + 0.5))
        return (rgba[0] << 24) | (rgba[1] << 16) | (rgba[2] << 8) | rgba[3]
    }
    
    public var hexValue: String { return String(format:"#%08X", hex) }
    public var rawValue: String { system_color_lut[self] ?? hex_color_lut[hex] ?? hexValue }
}

// color formatter for text input
class ColorFormatter: Formatter {
    override func string(for object: Any?) -> String? {
        guard let color = object as? Color else { return nil }
        return color.hexValue
    }
    
    override func getObjectValue(_ object: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard let color = Color(name: string) else { return false }
        object?.pointee = color as AnyObject; return true
    }
}
