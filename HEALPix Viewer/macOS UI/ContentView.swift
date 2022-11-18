//
//  ContentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

// asynchronous queue for user-initiated tasks
let userTaskQueue = DispatchQueue.global(qos: .userInitiated)

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
    @State private var infoview = false
    
    // open files
    @State private var loading = false
    @State private var file = [HpxFile]()
    @State private var loaded = [MapData]()
    @State private var selected: UUID? = nil
    
    // map to be displayed
    @State private var map: Map? = nil
    @State private var info: String? = nil
    
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
    @State private var datamin: Double = 0.0
    @State private var datamax: Double = 0.0
    @State private var rangemin: Double = 0.0
    @State private var rangemax: Double = 0.0
    
    @State private var modifier: BoundsModifier = .defaultValue
    
    // lighting toolbar
    @State private var lightingLat: Double = 45.0
    @State private var lightingLon: Double = -45.0
    @State private var lightingAmt: Double = 30.0
    
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
            NavigationList(loaded: $loaded, selected: $selected)
                .frame(width: 160)
            GeometryReader { geometry in
                ZStack {
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
                            LightingToolbar(lightingLat: $lightingLat, lightingLon: $lightingLon, lightingAmt: $lightingAmt)
                        }
                        MapView(map: $map, projection: $projection, magnification: $magnification, spin: $spin,
                                latitude: $latitude, longitude: $longitude, azimuth: $azimuth, background: $bgcolor,
                                lightingLat: $lightingLat, lightingLon: $lightingLon, lightingAmt: $lightingAmt)
                        if (colorbar) {
                            BarView(colorsheme: $colorscheme, background: $bgcolor)
                                .frame(height: geometry.size.width/20)
                            RangeToolbar(map: $map, modifier: $modifier,
                                         datamin: $datamin, datamax: $datamax,
                                         rangemin: $rangemin, rangemax: $rangemax)
                            .onChange(of: range) { value in colorize(map) }
                        }
                    }
                    .sheet(isPresented: $loading) {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Loading file...")
                        }
                        .padding(20)
                    }
                }
                if (infoview) {
                    ScrollView {
                        Text(info ?? "")
                            .lineLimit(nil)
                            .frame(width: geometry.size.width)
                            .font(Font.system(size: 13).monospaced())
                    }
                    .background(.thinMaterial)
                }
            }
        }
        .frame(
            minWidth:  800, idealWidth: 1280, maxWidth:  .infinity,
            minHeight: 600, idealHeight: 800, maxHeight: .infinity
        )
        .toolbar(id: "mainToolbar") {
            Toolbar(toolbar: $toolbar, colorbar: $colorbar, infoview: $infoview, magnification: $magnification, info: $info)
        }
        .navigationTitle(title)
        .onChange(of: selected) { value in
            if let map = loaded.first(where: { $0.id == value }) { info = map.info; load(map.map) }
        }
        .task {
            colorbar = UserDefaults.standard.bool(forKey: showColorBarKey)
            projection = Projection.value
            orientation = Orientation.value
            colorscheme = ColorScheme.value
            mincolor = colorscheme.colormap.min
            maxcolor = colorscheme.colormap.max
        }
        .task {
            observers.add(key: showColorBarKey) { old, new in
                guard let value = new as? Bool else { return }
                withAnimation { colorbar = value }
            }
            observers.add(key: Projection.appStorage) { old, new in
                guard let raw = new as? String, let mode = Projection(rawValue: raw) else { return }
                withAnimation { toolbar = .projection }; projection = mode
            }
            observers.add(key: Orientation.appStorage) { old, new in
                guard let raw = new as? String, let mode = Orientation(rawValue: raw) else { return }
                withAnimation { toolbar = (mode == .free) ? .orientation : .projection }; orientation = mode
            }
            observers.add(key: ColorScheme.appStorage) { old, new in
                guard let raw = new as? String, let mode = ColorScheme(rawValue: raw) else { return }
                withAnimation { toolbar = .color }
                
                colorscheme = mode
                mincolor = colorscheme.colormap.min
                maxcolor = colorscheme.colormap.max
            }
        }
        .task {
            open()
        }
    }
    
    // flat list of maps in opened files
    var opened: [MapData] { file.reduce([MapData]()) { $0 + $1.list } }
    
    // open file
    func open() {
        guard let url = showOpenPanel() else { return }
        
        userTaskQueue.async {
            self.loading = true; defer { self.loading = false }
            guard let file = read_hpxfile(url: url) else { return }
            
            self.file.append(file)
            self.loaded = self.opened
        }
    }
    
    // load map to view
    func load(_ map: Map) {
        self.map = map
        
        modifier = .full
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
