//
//  Color Mixer.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-09-26.
//

import SwiftUI

// color mixer primaries
struct Primaries: Equatable, Codable {
    var r = Color(red:1.0, green: 0.0, blue: 0.0, opacity: 1.0)
    var g = Color(red:0.0, green: 1.0, blue: 0.0, opacity: 1.0)
    var b = Color(red:0.0, green: 0.0, blue: 1.0, opacity: 1.0)
    var black = Color(red:0.0, green: 0.0, blue: 0.0, opacity: 1.0)
    var white = Color(red:1.0, green: 1.0, blue: 1.0, opacity: 1.0)
    var gamma = 0.0 // log2 scale
    var mode = Mixing.defaultValue
    var compress = false
}

extension Primaries: JsonRepresentable, Preference {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, black, white, gamma, mode, compress
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        r = try container.decode(Color.self, forKey: .red)
        g = try container.decode(Color.self, forKey: .green)
        b = try container.decode(Color.self, forKey: .blue)
        black = try container.decode(Color.self, forKey: .black)
        white = try container.decode(Color.self, forKey: .white)
        gamma = try container.decode(Double.self, forKey: .gamma)
        mode = try container.decode(Mixing.self, forKey: .mode)
        compress = try container.decode(Bool.self, forKey: .compress)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(r, forKey: .red)
        try container.encode(g, forKey: .green)
        try container.encode(b, forKey: .blue)
        try container.encode(black, forKey: .black)
        try container.encode(white, forKey: .white)
        try container.encode(gamma, forKey: .gamma)
        try container.encode(mode, forKey: .mode)
        try container.encode(compress, forKey: .compress)
    }
    
    // default value
    static let key = "primaries"
    static let defaultValue = Self()
}

// color mixing preference
enum Mixing: String, CaseIterable, Codable, Preference {
    case add = "Add"
    case mix = "Mix"
    case blend = "Blend"
    
    // help string
    var description: String {
        switch self {
            case .add:      return "Co-add RGB primaries as they are"
            case .mix:      return "Scale RGB primaries to achieve specified white point"
            case .blend:    return "Blend in perceptually uniform color space"
        }
    }
    
    // default value
    static let key = "mixing"
    static let defaultValue: Self = .blend
}
