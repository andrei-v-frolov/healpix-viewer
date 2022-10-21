//
//  Menus.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct Menus: Commands {
    // data source and projection
    @AppStorage(DataSource.appStorage) var dataSource = DataSource.defaultValue
    @AppStorage(DataConvolution.appStorage) var convolution = DataConvolution.defaultValue
    @AppStorage(Projection.appStorage) var projection = Projection.defaultValue
    @AppStorage(Orientation.appStorage) var orientation = Orientation.defaultValue
    
    // colorbar properties
    @AppStorage(ColorScheme.appStorage) var colorScheme = ColorScheme.defaultValue
    @AppStorage(DataTransform.appStorage) var dataTransform = DataTransform.defaultValue
    @AppStorage(DataBounds.appStorage) var dataBounds = DataBounds.defaultValue
    @AppStorage(BoundsModifier.appStorage) var boundsModifier = BoundsModifier.defaultValue
    
    // render colorbar?
    @AppStorage("showColorBar") var showColorBar = true
    
    // menu commands
    var body: some Commands {
        CommandMenu("Data") {
            Group {
                Picker("Source", selection: $dataSource) {
                    ForEach(DataSource.temperature, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(DataSource.polarization, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(DataSource.vector, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(DataSource.special, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach([DataSource.channel], id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Picker("Convolution", selection: $convolution) {
                    ForEach(DataConvolution.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Button("Kernel Length") {}
                }
                Picker("Projection", selection: $projection) {
                    ForEach(Projection.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Button("View Point") {}
                }
                Picker("Orientation", selection: $orientation) {
                    ForEach(Orientation.free, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(Orientation.galactic, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(Orientation.ecliptic, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }
            Divider()
            Group {
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Button("Below Minimum") {}
                    Button("Above Maximum") {}
                    Button("Invalid Data") {}
                    Divider()
                    Button("Background") {}
                }
                Picker("Data Range", selection: $boundsModifier) {
                    ForEach(BoundsModifier.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Picker("Transform", selection: $dataTransform) {
                    ForEach(DataTransform.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Picker("Apply...", selection: $dataTransform) {
                        Text("After Convolving")
                        Text("Before Convolving")
                    }
                }
                Picker("Bounds", selection: $dataBounds) {
                    ForEach(DataBounds.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }
            Divider()
            Toggle(isOn: $showColorBar) {
                Text("Show Color Bar")
            }
        }
        
        SidebarCommands()
        ToolbarCommands()
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
    case random = "Random Field"
    case channel = "Channel"
    
    // default value
    static let appStorage = "dataSource"
    static let defaultValue: Self = .i
    
    // collections
    static let temperature: [Self] = [.i]
    static let polarization: [Self] = [.q, .u, .e, .b, .p]
    static let vector: [Self] = [.x, .y, .v]
    static let special: [Self] = [.random]
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
enum Projection: String, CaseIterable {
    case mollweide = "Mollweide"
    case gnomonic = "Gnomonic"
    case lambert = "Lambert"
    case isometric = "Isometric"
    
    // default value
    static let appStorage = "projection"
    static let defaultValue: Self = .mollweide
}

// projection orientation lock
enum Orientation: String, CaseIterable, Preference {
    case drag = "Drag"
    case spin = "Spin"
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
    static let free: [Self] = [.drag, .spin]
    static let galactic: [Self] = [.equator, .north, .south]
    static let ecliptic: [Self] = [.eclipticEquator, .eclipticNorth, .eclipticSouth]
}

// color scheme
enum ColorScheme: String, CaseIterable, Preference {
    case planck = "Planck"
    case cmb = "HEALPix CMB"
    case grey = "Greyscale"
    case hot = "Hot"
    case cold = "Cold"
    case diff = "Difference Map"
    case freq = "Frequency Map"
    case grv = "GRV"
    case bgry = "BGRY"
    
    // default value
    static let appStorage = "colorScheme"
    static let defaultValue: Self = .planck
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
    case none = "Full"
    case symmetric = "Symmetric"
    case positive = "Positive"
    case negative = "Negative"
    
    // default value
    static let appStorage = "boundsModifier"
    static let defaultValue: Self = .none
}

// encapsulates @AppStorage preference properties
protocol Preference {
    static var appStorage: String { get }
    static var defaultValue: Self { get }
}
