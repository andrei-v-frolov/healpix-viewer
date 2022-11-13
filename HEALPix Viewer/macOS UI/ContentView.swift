//
//  ContentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

// number formatter common to most fields
let TwoDigitNumber: NumberFormatter = {
    let format = NumberFormatter()
    
    format.minimumFractionDigits = 2
    format.maximumFractionDigits = 2
    
    return format
}()

// main window view
struct ContentView: View {
    @State private var title = "CMB Viewer"
    @State private var toolbar = ShowToolbar.none
    @State private var colorbar = false
    
    // map to be displayed
    @State private var map: Map? = test
    
    // projection toolbar
    @State private var projection: Projection = .defaultValue
    @State private var orientation: Orientation = .defaultValue
    @State private var spin: Bool = true
    
    // magnification and orientation toolbar
    @State private var magnification: Double = 0.0
    
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var azimuth: Double = 0.0
    
    // color toolbar
    @State private var colorscheme: ColorScheme = .defaultValue
    @State private var mincolor = Color.blue
    @State private var maxcolor = Color.red
    @State private var nancolor = Color.green
    @State private var bgcolor = Color.clear
    
    // range toolbar
    @State private var datamin: Double = -1.0
    @State private var datamax: Double =  1.0
    @State private var rangemin: Double = -1.0
    @State private var rangemax: Double =  1.0
    
    @State private var modifier: BoundsModifier = .defaultValue
    
    // color mapper
    private let mapper = ColorMapper()
    
    // convenience wrapper for tracking color changes
    private struct Palette: Equatable {
        let colorscheme: ColorScheme
        let mincolor: Color
        let maxcolor: Color
        let nancolor: Color
    }
    
    private var colors: Palette { return Palette(colorscheme: colorscheme, mincolor: mincolor, maxcolor: maxcolor, nancolor: nancolor) }
    
    // convenience wrapper for tracking range changes
    private struct Bounds: Equatable {
        let min: Double
        let max: Double
    }
    
    private var range: Bounds { return Bounds(min: rangemin, max: rangemax) }
    
    // registered observers binding to application state
    var observers = Observers()
    
    // view layout
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
            }
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if (toolbar == .projection) {
                        ProjectionToolbar(projection: $projection, orientation: $orientation, spin: $spin)
                            .onChange(of: orientation) {
                                if ($0 != .free) {
                                    let (lat,lon,az) = $0.coords
                                    latitude = lat; longitude = lon; azimuth = az
                                }
                            }
                    }
                    if (toolbar == .orientation) {
                        OrientationToolbar(latitude: $latitude, longitude: $longitude, azimuth: $azimuth)
                            .onChange(of: latitude)  { value in orientation = .free }
                            .onChange(of: longitude) { value in orientation = .free }
                            .onChange(of: azimuth)   { value in orientation = .free }
                    }
                    if (toolbar == .color) {
                        ColorToolbar(colorscheme: $colorscheme,
                                     mincolor: $mincolor, maxcolor: $maxcolor,
                                     nancolor: $nancolor, bgcolor: $bgcolor)
                        .onChange(of: colors) { value in colorize(map) }
                    }
                    if (toolbar == .lighting) {
                        LightingToolbar()
                    }
                    MapView(map: $map, projection: $projection, magnification: $magnification, spin: $spin,
                            latitude: $latitude, longitude: $longitude, azimuth: $azimuth,
                            background: $bgcolor)
                    if (colorbar) {
                        BarView(colorsheme: $colorscheme, background: $bgcolor)
                            .frame(height: geometry.size.width/20)
                        RangeToolbar(map: $map, modifier: $modifier,
                                     datamin: $datamin, datamax: $datamax,
                                     rangemin: $rangemin, rangemax: $rangemax)
                        .onChange(of: range) { value in colorize(map) }
                    }
                }
            }
        }
        .frame(
            minWidth:  800, idealWidth: 1280, maxWidth:  .infinity,
            minHeight: 600, idealHeight: 800, maxHeight: .infinity
        )
        .toolbar(id: "mainToolbar") {
            Toolbar(toolbar: $toolbar, colorbar: $colorbar, magnification: $magnification)
        }
        .navigationTitle(title)
        .task {
            colorbar = UserDefaults.standard.bool(forKey: "showColorBar")
            projection = Projection.value
            orientation = Orientation.value
            colorscheme = ColorScheme.value
        }
        .task {
            observers.add(key: "showColorBar") { old, new in
                guard let value = new as? Bool else { return }
                withAnimation { colorbar = value }
            }
        }
    }
    
    // load map to view
    func load(_ map: Map) {
        self.map = map
        
        datamin = map.min; rangemin = datamin
        datamax = map.max; rangemax = datamax
        
        colorize(self.map)
    }
    
    // colorize map with current settings
    func colorize(_ map: Map?) {
        guard let map = map else { return }
        
        mapper.colorize(map: map, colormap: colorscheme.colormap,
                        mincolor: mincolor, maxcolor: maxcolor, nancolor: nancolor,
                        minvalue: rangemin, maxvalue: rangemax)
    }
}
