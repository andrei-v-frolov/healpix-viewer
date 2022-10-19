//
//  Menus.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct Menus: Commands {
    // data source and projection
    @AppStorage("dataSource") var dataSource = DataSource.i
    @AppStorage("convolution") var convolution = DataConvolution.none
    @AppStorage("projection") var projection = Projection.mollweide
    
    // colorbar properties
    @AppStorage("colorScheme") var colorScheme = ColorScheme.planck
    @AppStorage("dataTransform") var dataTransform = DataTransform.linear
    @AppStorage("dataBounds") var dataBounds = DataBounds.values
    @AppStorage("boundsModifier") var boundsModifier = BoundsModifier.none
    
    // render colorbar?
    @AppStorage("showColorBar") var showColorBar = true
    
    // menu commands
    var body: some Commands {
        CommandMenu("Data") {
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
            Divider()
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
enum DataSource: String, CaseIterable {
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
    
    // collections
    static let temperature: [Self] = [.i]
    static let polarization: [Self] = [.q, .u, .e, .b, .p]
    static let vector: [Self] = [.x, .y, .v]
    static let special: [Self] = [.random]
    
    static func change(to source: DataSource) {
        @AppStorage("dataSource") var dataSource = DataSource.i
        
        dataSource = source
    }
}

// line convolution direction to be applied
enum DataConvolution: String, CaseIterable {
    case none = "None"
    case polarization = "Polarization"
    case vector = "Vector Field"
    
    static func change(to direction: DataConvolution) {
        @AppStorage("convolution") var convolution = DataConvolution.none
        
        convolution = direction
    }
}

// spherical projection to be used
enum Projection: String, CaseIterable {
    case mollweide = "Mollweide"
    case gnomonic = "Gnomonic"
    case lambert = "Lambert"
    case isometric = "Isometric"
    
    static func change(to kind: Projection) {
        @AppStorage("projection") var projection = Projection.mollweide
        
        projection = kind
    }
}

// color scheme
enum ColorScheme: String, CaseIterable {
    case planck = "Planck"
    case cmb = "HEALPix CMB"
    case grey = "Greyscale"
    case hot = "Hot"
    case cold = "Cold"
    case diff = "Difference Map"
    case freq = "Frequency Map"
    case grv = "GRV"
    case bgry = "BGRY"
    
    static func change(to scheme: ColorScheme) {
        @AppStorage("colorScheme") var colorScheme = ColorScheme.planck
        
        colorScheme = scheme
    }
}

// color scheme
enum DataTransform: String, CaseIterable {
    case linear = "Linear"
    case log = "Logarithmic"
    case asinh = "asinh scaling"
    case equalize = "Equalize"
    case normalize = "Normalize"
    
    static func change(to transform: DataTransform) {
        @AppStorage("dataTransform") var dataTransform = DataTransform.linear
        
        dataTransform = transform
    }
}

// data bounds to be mapped to color bar
enum DataBounds: String, CaseIterable {
    case values = "Values"
    case percentile = "Percentile"
    
    static func change(to kind: DataBounds) {
        @AppStorage("dataBounds") var dataBounds = DataBounds.values
        
        dataBounds = kind
    }
}

// data bounds modifier
enum BoundsModifier: String, CaseIterable {
    case none = "Full"
    case symmetric = "Symmetric"
    case positive = "Positive"
    case negative = "Negative"
    
    static func change(to kind: BoundsModifier) {
        @AppStorage("boundsModifier") var boundsModifier = BoundsModifier.none
        
        boundsModifier = kind
    }
}
