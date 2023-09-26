//
//  Line Convolution.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-09-26.
//

import Foundation

// line convolution
enum LineConvolution: String, CaseIterable, Codable, Preference {
    case none = "None"
    case vector = "Vector Field"
    case polarization = "Polarization"
    
    // default value
    static let key = "convolution"
    static let defaultValue: Self = .none
}
