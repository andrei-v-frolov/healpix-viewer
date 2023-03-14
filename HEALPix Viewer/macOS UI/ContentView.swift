//
//  ContentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import MetalKit
import MetalPerformanceShaders
import UniformTypeIdentifiers

// asynchronous queues for user-initiated tasks
let userTaskQueue = DispatchQueue(label: "serial", qos: .userInitiated)
let analysisQueue = DispatchQueue(label: "analysis", qos: .userInitiated, attributes: [.concurrent])

// main window view
struct ContentView: View {
    @State private var title = "CMB Viewer"
    @State private var toolbar = ShowToolbar.none
    @State private var overlay = ShowOverlay.none
    @State private var colorbar = false
    
    // open files
    @State private var loading = false
    @State private var file = [HpxFile]()
    @State private var loaded = [MapData]()
    @State private var selected: UUID? = nil
    
    // save images
    @State private var saving = false
    @State private var width: Int = 1920
    @State private var oversampling: Int = 2
    @State private var withDatarange: Bool = true
    @State private var withAnnotation: Bool = true
    
    // drag and drop
    @State private var targeted = false
    
    // map to be displayed
    @State private var map: Map? = nil
    @State private var cdf: [Double]? = nil
    @State private var info: String? = nil
    @State private var annotation: String = "TEMPERATURE [μK]"
    
    // computed map cache
    @State private var ranked: [UUID: CpuMap] = [UUID: CpuMap]()
    @State private var transformed: [UUID: GpuMap] = [UUID: GpuMap]()
    
    // progress analyzing data
    @State private var scheduled: Int = 0
    @State private var completed: Int = 0
    private var progress: Double { Double(completed)/Double(scheduled) }
    
    // projection toolbar
    @State private var projection: Projection = .defaultValue
    @State private var orientation: Orientation = .defaultValue
    @State private var spin: Bool = false
    
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
    
    // transform toolbar
    @State private var transform: DataTransform = .defaultValue
    @State private var mu: Double = 0.0
    @State private var sigma: Double = 0.0
    @State private var mumin: Double = 0.0
    @State private var mumax: Double = 0.0
    
    // lighting toolbar
    @State private var lighting = Lighting(enabled: false, lat: 45.0, lon: 45.0, amt: 30.0)
    
    // cursor readout
    @State private var cursor = Cursor(hover: false, lat: 0.0, lon: 0.0, pix: 0, val: 0.0)
    
    // associated views
    @State private var mapview: ProjectedView? = nil
    @State private var barview: ColorbarView? = nil
    private var window: NSWindow? { mapview?.window }
    
    // data transformer
    private let transformer = DataTransformer()
    
    // color mapper
    private let mapper = ColorMapper()
    
    // convenience wrapper for tracking viewpoint changes
    private struct Viewpoint: Equatable {
        let latitude: Double
        let longitude: Double
        let azimuth: Double
    }
    
    private var viewpoint: Viewpoint { Viewpoint(latitude: latitude, longitude: longitude, azimuth: azimuth) }
    
    // convenience wrapper for tracking color changes
    private struct Palette: Equatable {
        let colorscheme: ColorScheme
        let mincolor: Color
        let maxcolor: Color
        let nancolor: Color
    }
    
    private var colors: Palette { Palette(colorscheme: colorscheme, mincolor: mincolor, maxcolor: maxcolor, nancolor: nancolor) }
    
    // convenience wrapper for tracking range changes
    private struct Bounds: Equatable {
        let min: Double
        let max: Double
    }
    
    private var range: Bounds { Bounds(min: rangemin, max: rangemax) }
    
    // convenience wrapper for tracking transform changes
    private struct Transform: Equatable {
        let transform: DataTransform
        let mu: Double
        let sigma: Double
        
        static func == (a: Self, b: Self) -> Bool {
            return (a.transform == b.transform) &&
                   (a.transform.mu ? a.mu == b.mu : true) &&
                   (a.transform.sigma ? a.sigma == b.sigma : true)
        }
    }
    
    private var function: Transform { Transform(transform: transform, mu: mu, sigma: sigma) }
    
    // variables signalling action
    @Binding var askToOpen: Bool
    @Binding var askToSave: Bool
    
    // registered observers binding to application state
    @State private var observers: Observers? = nil
    
    // view layout
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                NavigationList(loaded: $loaded, selected: $selected)
                    .frame(width: 160)
                if (scheduled > 0) {
                    Divider()
                    Text("Analyzing Data...").padding([.top], 5)
                    ProgressView(value: progress).padding([.leading,.trailing], 10).padding([.bottom], 2)
                    .onChange(of: progress) { value in if (value == 1.0) { scheduled = 0; completed = 0 } }
                }
            }
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        if (toolbar == .projection) {
                            ProjectionToolbar(projection: $projection, orientation: $orientation, spin: $spin)
                        }
                        if (toolbar == .orientation) {
                            OrientationToolbar(latitude: $latitude, longitude: $longitude, azimuth: $azimuth)
                            .onChange(of: viewpoint)  { value in orientation = .free }
                        }
                        if (toolbar == .color) {
                            ColorToolbar(colorscheme: $colorscheme,
                                         mincolor: $mincolor, maxcolor: $maxcolor,
                                         nancolor: $nancolor, bgcolor: $bgcolor)
                        }
                        if (toolbar == .transform) {
                            TransformToolbar(transform: $transform, mu: $mu, sigma: $sigma, selected: $selected, ranked: $ranked, mumin: $mumin, mumax: $mumax)
                        }
                        if (toolbar == .lighting) {
                            LightingToolbar(lighting: $lighting)
                        }
                        ZStack(alignment: .top) {
                            MapView(map: $map, projection: $projection, magnification: $magnification, spin: $spin,
                                    orientation: $orientation, latitude: $latitude, longitude: $longitude, azimuth: $azimuth,
                                    background: $bgcolor, lighting: $lighting, cursor: $cursor, mapview: $mapview)
                            .onDrag {
                                let w = geometry.size.width, h = projection.height(width: w), none = NSItemProvider()
                                guard let url = tmpfile(), let image = mapview?.image(width: Int(w), height: Int(h)) else { return none }
                                
                                saveAsPNG(image, url: url); tmpfiles.append(url)
                                return NSItemProvider(contentsOf: url) ?? none
                            }
                            if (cursor.hover) {
                                CursorView(cursor: $cursor)
                            }
                        }
                        if (colorbar) {
                            BarView(colorsheme: $colorscheme, background: $bgcolor, barview: $barview)
                            .frame(height: 1.5*geometry.size.width/ColorbarView.aspect)
                            .onDrag {
                                let w = geometry.size.width, h = w/ColorbarView.aspect, none = NSItemProvider()
                                guard let url = tmpfile(), let image = barview?.image(width: Int(w), height: Int(h)) else { return none }
                                
                                saveAsPNG(image, url: url); tmpfiles.append(url)
                                return NSItemProvider(contentsOf: url) ?? none
                            }
                            RangeToolbar(map: $map, modifier: $modifier,
                                         datamin: $datamin, datamax: $datamax,
                                         rangemin: $rangemin, rangemax: $rangemax)
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
                                       withColorbar: $colorbar, withDatarange: $withDatarange,
                                       withAnnotation: $withAnnotation, annotation: $annotation).padding(20)
                            Divider()
                            HStack {
                                Button { saving = false } label: {
                                    Text("Cancel").padding(20)
                                }
                                Spacer().frame(width: 30)
                                Button { saving = false; DispatchQueue.main.async { self.save() } } label: {
                                    Text("Export").foregroundColor(Color.accentColor).padding(20)
                                }
                            }
                            .padding(10)
                        }
                    }
                }
                Group {
                    if #available(macOS 13.0, *) {
                    if (overlay == .statview) {
                        StatView(cdf: $cdf, rangemin: $rangemin, rangemax: $rangemax)
                        .background(.thinMaterial)
                        .onChange(of: cdf) { value in if (value == nil) { overlay = .none } }
                    } }
                    if (overlay == .infoview) {
                        ScrollView {
                            Text(info ?? "")
                                .lineLimit(nil)
                                .frame(width: geometry.size.width)
                                .font(Font.system(size: 13).monospaced())
                        }
                        .background(.thinMaterial)
                    }
                }
                if (targeted) {
                    HStack { Spacer(); VStack { Spacer(); DropView(); Spacer() }; Spacer() }
                }
            }
        }
        .frame(
            minWidth:  940, idealWidth: 1280, maxWidth:  .infinity,
            minHeight: 600, idealHeight: 800, maxHeight: .infinity
        )
        .toolbar(id: "mainToolbar") {
            Toolbar(toolbar: $toolbar, overlay: $overlay, colorbar: $colorbar, lighting: $lighting.enabled, magnification: $magnification, cdf: $cdf, info: $info)
        }
        .navigationTitle(title)
        .onChange(of: selected) { value in
            if let map = loaded.first(where: { $0.id == value }) {
                info = map.info; transform(map.map)
                title = "\(map.name)[\(map.file)]"
                annotation = "\(map.name) [\(map.unit)]"
                mumin = map.map.min; mumax = map.map.max
            }
        }
        .onChange(of: orientation) { value in
            guard (value != .free) else { return }
            
            let (lat,lon,az) = value.coords
            latitude = lat; longitude = lon; azimuth = az
        }
        .onChange(of: function) { value in transform() }
        .onChange(of: colors) { value in colorize() }
        .onChange(of: range) { value in colorize() }
        .onChange(of: askToOpen) { value in
            if (window?.isKeyWindow == true && value) {
                askToOpen = false; DispatchQueue.main.async { self.open() }
            }
        }
        .onChange(of: askToSave) { value in
            if (window?.isKeyWindow == true && value) {
                askToSave = false; saving = true
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
            lighting.enabled = UserDefaults.standard.bool(forKey: lightingKey)
            projection = Projection.value
            orientation = Orientation.value
            colorscheme = ColorScheme.value
            mincolor = colorscheme.colormap.min
            maxcolor = colorscheme.colormap.max
            transform = DataTransform.value
            
            DispatchQueue.main.async { spin = true }
        }
        .task {
            let observers = Observers(); self.observers = observers
            
            observers.add(key: cursorKey) { old, new in
                guard let value = new as? Bool else { return }
                if (!value) { cursor.hover = false }
            }
            observers.add(key: showColorBarKey) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let value = new as? Bool else { return }
                withAnimation { colorbar = value }
            }
            observers.add(key: lightingKey) { old, new in
                guard let value = new as? Bool else { return }
                lighting.enabled = value
            }
            observers.add(key: Projection.appStorage) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Projection(rawValue: raw) else { return }
                withAnimation { toolbar = .projection }; projection = mode
            }
            observers.add(key: Orientation.appStorage) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Orientation(rawValue: raw) else { return }
                withAnimation { toolbar = (mode == .free) ? .orientation : .projection }; orientation = mode
            }
            observers.add(key: ColorScheme.appStorage) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = ColorScheme(rawValue: raw) else { return }
                withAnimation { toolbar = .color }
                
                colorscheme = mode
                mincolor = colorscheme.colormap.min
                maxcolor = colorscheme.colormap.max
            }
            observers.add(key: DataSource.appStorage) {  old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let data = DataSource(rawValue: raw) else { return }
                for map in loaded { if (MapCard.type(map.name) == data) { selected = map.id; break } }
            }
            observers.add(key: DataTransform.appStorage) {  old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = DataTransform(rawValue: raw) else { return }
                withAnimation { toolbar = .transform }; transform = mode
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
            
            // select default data source
            for map in file.list {
                if (MapCard.type(map.name) == DataSource.value) { self.selected = map.id; break }
            }
            
            // dispatch maps for analysis
            for map in file.list {
                let map = map.map, n = Double(map.npix), workload = Int(n*log(1+n))
                scheduled += workload; analysisQueue.async {
                    map.index(); if (map.id == selected) { cdf = map.cdf?.map { transform.f($0, mu: mu, sigma: sigma) } }
                    ranked[map.id] = map.ranked(); if DataTransform.cdf.contains(transform) { transform() }
                    completed += workload
                }
            }
        }
    }
    
    // load map to view
    func load(_ map: Map) {
        let later = colorbar && (rangemin != map.min || rangemax != map.max)
        
        self.map = map; self.cdf = map.cdf
        
        modifier = .full
        datamin = map.min; rangemin = datamin
        datamax = map.max; rangemax = datamax
        
        if !later { colorize(self.map) }
    }
    
    // colorize map with current settings
    func colorize(_ map: Map? = nil) {
        guard let map = map ?? self.map else { return }
        
        mapper.colorize(map: map, colormap: colorscheme.colormap,
                        mincolor: mincolor, maxcolor: maxcolor, nancolor: nancolor,
                        minvalue: rangemin, maxvalue: rangemax)
    }
    
    // transform map with current settings
    func transform(_ map: Map? = nil) {
        guard let map = map ?? loaded.first(where: { $0.id == selected })?.map else { return }
        
        switch transform {
            case .none: load(map)
            case .equalize: if let map = ranked[map.id] { load(map) }
            case .normalize: if let map = ranked[map.id], let output = transformer.transform(map: map, function: transform, recycle: transformed[map.id]) { transformed[map.id] = output; load(output) }
            default: if let output = transformer.transform(map: map, function: transform, mu: mu, sigma: sigma, recycle: transformed[map.id]) { transformed[map.id] = output; load(output) }
        }
    }
    
    // render annotated map texture for export
    func render() -> MTLTexture? {
        // set up dimensions for borderless map
        let width = Double(width*oversampling)
        var height = projection.height(width: width), shift = 0.0
        let thickness = width/ColorbarView.aspect
        if (colorbar) { height += 2.0*thickness; shift += thickness }
        if (colorbar && withDatarange) { height += thickness; shift += thickness/2.0 }
        let w = Int(width), h = Int(height), t = Int(thickness)
        
        // render map texture and annotate it if requested
        guard let texture = mapview?.image(width: w, height: h, shift: (0,shift)) else { return nil }
        let output = (oversampling > 1) ? PNGTexture(width: w/oversampling, height: h/oversampling) : texture
        
        if (colorbar && withDatarange) {
            let scale = " (\(transform.rawValue.lowercased()) scale)"
            let annotation = (transform != .none) ? annotation + scale : annotation
            annotate(texture, height: t, min: rangemin, max: rangemax, annotation: withAnnotation ? annotation : nil, background: bgcolor.cgColor)
        }
        
        if (colorbar || oversampling > 1) {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let queue = device.makeCommandQueue(),
                  let command = queue.makeCommandBuffer() else { return nil }
            
            // render colorbar and copy it in
            if (colorbar) {
                guard let bar = barview?.image(width: w, height: 2*t),
                      let encoder = command.makeBlitCommandEncoder() else { return nil }
                
                encoder.copy(from: bar, sourceSlice: 0, sourceLevel: 0,
                             sourceOrigin: MTLOriginMake(0,0,0), sourceSize: MTLSizeMake(w,2*t,1),
                             to: texture, destinationSlice: 0, destinationLevel: 0,
                             destinationOrigin: MTLOriginMake(0, withDatarange ? t : 0, 0))
                encoder.endEncoding()
            }
            
            // scale down oversampled texture
            if (oversampling > 1) {
                let scaler = MPSImageLanczosScale(device: device)
                let input = MPSImage(texture: texture, featureChannels: 4)
                let output = MPSImage(texture: output, featureChannels: 4)
                
                scaler.encode(commandBuffer: command, sourceImage: input, destinationImage: output)
            }
            
            command.commit()
            command.waitUntilCompleted()
        }
        
        return output
    }
    
    // save annotated map
    func save(_ url: URL? = nil) {
        guard let url = url ?? showSavePanel() else { return }
        if let output = render() { saveAsPNG(output, url: url) }
    }
}

// annotate bottom part of a texture with data range labels and (optionally) a string
func annotate(_ texture: MTLTexture, height h: Int, min: Double, max: Double, format: String = "%+.6g", annotation: String? = nil, font fontname: String = "SF Compact", color: CGColor = .black, background: CGColor? = nil) {
    let w = texture.width, region = MTLRegionMake2D(0,0,w,h)
    
    // allocate buffer for the annotation region
    let buffer = UnsafeMutableRawPointer.allocate(byteCount: 4*w*h, alignment: 1024)
    texture.getBytes(buffer, bytesPerRow: 4*w, from: region, mipmapLevel: 0)
    defer { buffer.deallocate() }
    
    // create graphics context
    let rgba = CGImageAlphaInfo.premultipliedLast.rawValue
    
    guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: buffer, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: 4*w,
                                  space: srgb, bitmapInfo: rgba) else { return }
    
    // set up coordinates for off-screen image
    context.translateBy(x: 0.0, y: CGFloat(h))
    context.scaleBy(x: 1.0, y: -1.0)
    
    // clear the background texture content
    let rect = CGRect(x: 0, y: 0, width: w, height: h); context.clear(rect)
    
    // fill the background if requested
    if let background = background { context.setFillColor(background); context.fill(rect) }
    
    // set up font for annotations
    let font = CTFontCreateWithName(fontname as CFString, CGFloat(h)/1.2, nil)
    let attr: [NSAttributedString.Key : Any] = [.font: font, .foregroundColor: color]
    
    // data range labels
    let min = NSAttributedString(string: String(format: format, min), attributes: attr)
    let max = NSAttributedString(string: String(format: format, max), attributes: attr)
    
    // compute bounding rectangles
    let minline = CTLineCreateWithAttributedString(min), minrect = CTLineGetImageBounds(minline, context)
    let maxline = CTLineCreateWithAttributedString(max), maxrect = CTLineGetImageBounds(maxline, context)
    
    // common baseline for the labels
    let base = CGFloat(h)/2.0 - (minrect.minY+minrect.height+maxrect.minY+maxrect.height)/4.0
    
    // render data bounds labels
    context.textPosition = CGPoint(x: base, y: base); CTLineDraw(minline, context)
    context.textPosition = CGPoint(x: CGFloat(w)-maxrect.width-base, y: base); CTLineDraw(maxline, context)
    
    // render annotation if supplied
    if let annotation = annotation {
        let string = NSAttributedString(string: annotation, attributes: attr)
        let line = CTLineCreateWithAttributedString(string), rect = CTLineGetImageBounds(line, context)
        
        context.textPosition = CGPoint(x: (CGFloat(w)-rect.width)/2.0, y: base); CTLineDraw(line, context)
    }
    
    context.flush()
    
    texture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: w*4)
}
