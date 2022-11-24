//
//  ContentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import UniformTypeIdentifiers

// asynchronous queue for user-initiated tasks
let userTaskQueue = DispatchQueue(label: "serial", qos: .userInitiated)

// callback wrapper to determine view window
struct Window {
    let callback: () -> NSWindow?
    func callAsFunction() -> NSWindow? { return callback() }
}

// callback wrapper to render off-screen texture
struct Texture {
    let callback: (Int, Int, Anchor) -> MTLTexture?
    func callAsFunction(width w: Int, height h: Int, anchor a: Anchor = .c) -> MTLTexture? { return callback(w, h, a) }
}

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
    
    // save images
    @State private var saving = false
    @State private var width: Double = 1920
    @State private var oversampling: Int = 2
    @State private var withColorbar: Bool = true
    @State private var withDatarange: Bool = true
    @State private var withAnnotation: Bool = true
    
    // drag and drop
    @State private var targeted = false
    
    // map to be displayed
    @State private var map: Map? = nil
    @State private var info: String? = nil
    @State private var annotation: String = "TEMPERATURE [μK]"
    
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
    @State private var nancolor = Color.gray
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
    
    // window associated with the view
    @State private var window: Window = Window { return nil }
    @State private var mapImage: Texture = Texture { _,_,_ in return nil }
    @State private var barImage: Texture = Texture { _,_,_ in return nil }
    
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
    
    // variables signalling action
    @Binding var askToOpen: Bool
    @Binding var askToSave: Bool
    
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
                                lightingLat: $lightingLat, lightingLon: $lightingLon, lightingAmt: $lightingAmt,
                                window: $window, image: $mapImage)
                        .onDrag {
                            let w = geometry.size.width, h = projection.height(width: w), none = NSItemProvider()
                            guard let url = tmpfile(), let image = mapImage(width: Int(w), height: Int(h)) else { return none }
                            
                            saveAsPNG(image, url: url); tmpfiles.append(url)
                            return NSItemProvider(contentsOf: url) ?? none
                        }
                        if (colorbar) {
                            BarView(colorsheme: $colorscheme, background: $bgcolor, image: $barImage)
                            .frame(height: 1.5*geometry.size.width/ColorbarView.aspect)
                            .onDrag {
                                let w = geometry.size.width, h = w/ColorbarView.aspect, none = NSItemProvider()
                                guard let url = tmpfile(), let image = barImage(width: Int(w), height: Int(h)) else { return none }
                                
                                saveAsPNG(image, url: url); tmpfiles.append(url)
                                return NSItemProvider(contentsOf: url) ?? none
                            }
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
                    .sheet(isPresented: $saving) {
                        VStack(spacing: 0) {
                            Text("Export map as PNG image...").font(.largeTitle).padding(20)
                            Divider()
                            ExportView(width: $width, oversampling: $oversampling,
                                       withColorbar: $withColorbar, withDatarange: $withDatarange,
                                       withAnnotation: $withAnnotation, annotation: $annotation).padding(20)
                            Divider()
                            HStack {
                                Button { saving = false } label: { Text("Cancel") }
                                Button { saving = false } label: { Text("Export") }
                            }
                            .padding(10)
                        }
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
                if (targeted) {
                    HStack { Spacer(); VStack { Spacer(); DropView(); Spacer() }; Spacer() }
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
            if let map = loaded.first(where: { $0.id == value }) {
                info = map.info; load(map.map)
                title = "\(map.name)[\(map.file)]"
                annotation = "\(map.name) [\(map.unit)]"
            }
        }
        .onChange(of: askToOpen) { value in
            if (window()?.isKeyWindow == true && value) {
                askToOpen = false; DispatchQueue.main.async { self.open() }
            }
        }
        .onChange(of: askToSave) { value in
            if (window()?.isKeyWindow == true && value) {
                askToSave = false; DispatchQueue.main.async { self.save() }
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $targeted) { provider in
            guard let type = UTType.healpix.tags[UTTagClass.filenameExtension] else { return false }
            
            var dispatched = false
            
            for p in provider {
                p.loadObject(ofClass: NSURL.self) { object, error in
                    guard let url = object as? URL? else { return }
                    guard let ext = url?.pathExtension.lowercased(), type.contains(ext) else { return }
                    
                    open(url); dispatched = true
                }
            }
            
            return dispatched
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
                guard (window()?.isKeyWindow == true) else { return }
                guard let value = new as? Bool else { return }
                withAnimation { colorbar = value }
            }
            observers.add(key: Projection.appStorage) { old, new in
                guard (window()?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Projection(rawValue: raw) else { return }
                withAnimation { toolbar = .projection }; projection = mode
            }
            observers.add(key: Orientation.appStorage) { old, new in
                guard (window()?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Orientation(rawValue: raw) else { return }
                withAnimation { toolbar = (mode == .free) ? .orientation : .projection }; orientation = mode
            }
            observers.add(key: ColorScheme.appStorage) { old, new in
                guard (window()?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = ColorScheme(rawValue: raw) else { return }
                withAnimation { toolbar = .color }
                
                colorscheme = mode
                mincolor = colorscheme.colormap.min
                maxcolor = colorscheme.colormap.max
            }
            observers.add(key: DataSource.appStorage) {  old, new in
                guard (window()?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let data = DataSource(rawValue: raw) else { return }
                for map in loaded { if (MapCard.type(map.name) == data) { selected = map.id; break } }
            }
        }
    }
    
    // flat list of maps in opened files
    var opened: [MapData] { file.reduce([MapData]()) { $0 + $1.list } }
    
    // open file
    func open(_ url: URL? = nil) {
        guard let url = url ?? showOpenPanel() else { return }
        
        userTaskQueue.async {
            self.loading = true; defer { self.loading = false }
            guard let file = read_hpxfile(url: url) else { return }
            
            self.file.append(file)
            self.loaded = self.opened
            
            for map in file.list {
                if (MapCard.type(map.name) == DataSource.value) { self.selected = map.id; break }
            }
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
    
    // ...
    func save(_ url: URL? = nil) {
        print("Saving file as...")
        saving = true
    }
}
