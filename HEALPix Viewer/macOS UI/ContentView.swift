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

// main window view
struct ContentView: View {
    // exposed views
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
    @AppStorage(dragSettingsKey) var drag = Export.drag
    @AppStorage(exportSettingsKey) var export = Export.save
    @AppStorage(annotationFontKey) var font = FontPreference.defaultValue
    @AppStorage(annotationColorKey) var color = Color.defaultValue
    
    // drag and drop
    @State private var targeted = false
    
    // map to be displayed
    @State private var map: Map? = nil
    @State private var cdf: [Double]? = nil
    @State private var data: MapData? = nil
    @State private var info: String? = nil
    @State private var ranked: Bool = false
    @State private var annotation: String = "TEMPERATURE [μK]"
    
    // progress analyzing data
    @State private var scheduled: Int = 0
    @State private var completed: Int = 0
    private var progress: Double { Double(completed)/Double(scheduled) }
    
    // view state
    @Binding var clipboard: ViewState
    @State private var state = ViewState()
    @State private var magnification: Double = 0.0
    @AppStorage(viewFromInsideKey) var inside: Bool = true
    
    // view state preferences
    @AppStorage(keepStateKey) var keepState = StateMask.keep
    @AppStorage(copyStateKey) var copyState = StateMask.copy
    
    // data range
    @State private var datamin: Double = 0.0
    @State private var datamax: Double = 0.0
    
    // transform range
    @State private var mumin: Double = 0.0
    @State private var mumax: Double = 0.0
    
    // lighting toolbar
    @AppStorage(lightingKey) var lighting = false
    
    // cursor readout
    @State private var cursor = Cursor()
    
    // associated views
    @State private var mapview: ProjectedView? = nil
    @State private var barview: ColorbarView? = nil
    private var window: NSWindow? { mapview?.window }
    
    // data transformer
    private let transformer = DataTransformer()
    
    // color mapper
    private let mapper = ColorMapper()
    
    // variable signalling action
    @Binding var action: MenuAction
    
    // registered observers binding to application state
    @State private var observers: Observers? = nil
    
    // view layout
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                NavigationList(loaded: $loaded, selected: $selected)
                    .frame(minWidth: 210, maxWidth: .infinity)
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
                            ProjectionToolbar(projection: $state.projection, orientation: $state.view.orientation, inside: $inside)
                        }
                        if (toolbar == .orientation) {
                            OrientationToolbar(view: $state.view)
                                .onChange(of: state.view)  { value in state.view.orientation = .free }
                        }
                        if (toolbar == .color) {
                            ColorToolbar(palette: $state.palette)
                        }
                        if (toolbar == .transform) {
                            TransformToolbar(transform: $state.transform, ranked: $ranked, mumin: $mumin, mumax: $mumax)
                        }
                        if (toolbar == .lighting) {
                            LightingToolbar(light: $state.light)
                        }
                        ZStack(alignment: .top) {
                            MapView(map: $map, projection: $state.projection, viewpoint: $state.view, magnification: $magnification,
                                    background: $state.palette.bg, light: $state.light, cursor: $cursor, mapview: $mapview)
                            .onDrag {
                                let w = geometry.size.width, h = state.projection.height(width: w), none = NSItemProvider()
                                guard let url = tmpfile(), let image = mapview?.image(width: Int(w), height: Int(h)) else { return none }
                                
                                saveAsImage(image, url: url); tmpfiles.append(url)
                                return NSItemProvider(contentsOf: url) ?? none
                            }
                            if (cursor.hover) {
                                CursorView(cursor: $cursor)
                            }
                        }
                        if (colorbar) {
                            BarView(palette: $state.palette, barview: $barview)
                            .frame(height: 1.5*geometry.size.width/ColorbarView.aspect)
                            .onDrag {
                                let w = geometry.size.width, h = w/ColorbarView.aspect, none = NSItemProvider()
                                guard let url = tmpfile(), let image = barview?.image(width: Int(w), height: Int(h)) else { return none }
                                
                                saveAsImage(image, url: url); tmpfiles.append(url)
                                return NSItemProvider(contentsOf: url) ?? none
                            }
                            RangeToolbar(range: $state.range, datamin: $datamin, datamax: $datamax)
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
                            Text("Export map as \(export.format.rawValue) image...").font(.largeTitle).padding(20).frame(minWidth: 380)
                            Divider()
                            ExportView(settings: $export, colorbar: $colorbar,
                                       annotation: $annotation, font: $font.nsFont, color: $color).padding(20)
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
                        StatView(cdf: $cdf, range: $state.range)
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
            minWidth:  990, idealWidth: 1280, maxWidth:  .infinity,
            minHeight: 660, idealHeight: 800, maxHeight: .infinity
        )
        .toolbar(id: "mainToolbar") {
            Toolbar(toolbar: $toolbar, overlay: $overlay, colorbar: $colorbar, lighting: $lighting, magnification: $magnification, cdf: $cdf, info: $info)
        }
        .navigationTitle(title)
        .onChange(of: selected) { value in load(value) }
        .onChange(of: state.view.orientation) { value in
            guard (value != .free) else { return }
            (state.view.lat, state.view.lon, state.view.az) = value.coords
        }
        .onChange(of: state.transform) { value in transform() }
        .onChange(of: state.palette) { value in colorize() }
        .onChange(of: state.range) { value in colorize() }
        .onChange(of: state) { value in preview() }
        .onChange(of: inside) { value in preview() }
        .onChange(of: action) { value in
            guard (value != .none && window?.isKeyWindow == true) else { return }
            
            switch value {
                case .open: DispatchQueue.main.async { self.open() }
                case .save: saving = true
                case .copyStyle:
                    clipboard = state
                case .pasteStyle:
                    state.update(clipboard, mask: copyState)
                case .pasteView:
                    state.projection = clipboard.projection
                    state.view = clipboard.view
                case .pasteColor:
                    state.palette = clipboard.palette
                    state.transform = clipboard.transform
                    state.range = clipboard.range
                case .pasteLight:
                    state.light = clipboard.light
                case .pasteAll:
                    state = clipboard
                default: break
            }
            
            action = .none
        }
        .onChange(of: lighting) { value in
            if (!value && toolbar == .lighting) { withAnimation { toolbar = .none } }; preview()
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
            state.projection = Projection.value
            state.view.orientation = Orientation.value
            state.palette.scheme = ColorScheme.value
            state.transform.f = Function.value
        }
        .task {
            let observers = Observers(); self.observers = observers
            
            observers.add(key: showColorBarKey) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let value = new as? Bool else { return }
                withAnimation { colorbar = value }
            }
            observers.add(key: Projection.key) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Projection(rawValue: raw) else { return }
                withAnimation { toolbar = .projection }; state.projection = mode
            }
            observers.add(key: Orientation.key) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Orientation(rawValue: raw) else { return }
                withAnimation { toolbar = (mode == .free) ? .orientation : .projection }; state.view.orientation = mode
            }
            observers.add(key: ColorScheme.key) { old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = ColorScheme(rawValue: raw) else { return }
                withAnimation { toolbar = .color }; state.palette.scheme = mode
            }
            observers.add(key: DataSource.key) {  old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let data = DataSource(rawValue: raw) else { return }
                for map in loaded { if (MapCard.type(map.name) == data) { selected = map.id; break } }
            }
            observers.add(key: Function.key) {  old, new in
                guard (window?.isKeyWindow == true) else { return }
                guard let raw = new as? String, let mode = Function(rawValue: raw) else { return }
                withAnimation { toolbar = .transform }; state.transform.f = mode
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
            
            // dispatch maps for analysis
            for map in file.list {
                map.settings.update(state, mask: keepState)
                
                let m = map.data, n = Double(m.npix), workload = Int(n*log(1+n))
                scheduled += workload; analysisQueue.async {
                    m.index(); map.ranked = m.ranked(); load(); completed += workload
                }
            }
            
            // select default data source
            for map in file.list {
                if (MapCard.type(map.name) == DataSource.value) { self.selected = map.id; break }
            }
        }
    }
    
    // load map to view
    func load(_ map: Map) {
        self.map = map; cdf = map.cdf; datamin = map.min; datamax = map.max
        if keepState.range, let state = map.state { self.state.range = state.range }
        else { self.state.range = Bounds(mode: .full, min: datamin, max: datamax) }
        
        colorize(map)
    }
    
    // load cached map data
    func load(_ map: MapData) {
        data = map; info = map.info
        ranked = (map.ranked != nil)
        title = "\(map.name)[\(map.file)]"
        annotation = "\(map.name) [\(map.unit)]"
        mumin = map.data.min; mumax = map.data.max
        
        transform(map); load(map.map); preview()
    }
    
    // load map with settings
    func load(_ id: UUID? = nil) {
        guard let map = loaded.first(where: { $0.id == id ?? selected }) else { return }
        
        // stash current settings
        data?.settings = state
        
        // load stored settings and map data
        state.update(map.settings, mask: keepState); load(map)
    }
    
    // colorize map with specified settings
    func colorize(_ map: Map? = nil, color: Palette? = nil, range: Bounds? = nil) {
        let color = ColorBar(palette: color ?? state.palette, range: range ?? state.range)
        guard var map = map ?? self.map, map.state != color else { return }
        
        // dispatch color mapper
        mapper.colorize(map: map, color: color.palette, range: color.range)
        map.state = color
    }
    
    // transform map with specified settings
    func transform(_ map: MapData? = nil, transform: Transform? = nil) {
        let transform = transform ?? state.transform
        guard let map = map ?? data, map.state != transform else { return }
        
        // dispatch data transform
        switch transform.f {
            case .none, .equalize: break
            case .normalize: if let ranked = map.ranked, let buffer = transformer.apply(map: ranked, transform: transform, recycle: map.buffer) { map.buffer = buffer } else { return }
            default: if let buffer = transformer.apply(map: map.data, transform: transform, recycle: map.buffer) { map.buffer = buffer } else { return }
        }
        
        // update current state
        map.state = transform; load(map.map)
    }
    
    // render map preview
    func preview() {
        guard let map = data, let mapview = mapview else { return }
        DispatchQueue.main.async { mapview.render(to: map.preview, magnification: 0.0, padding: 0.02, background: .clear); map.refresh() }
    }
    
    // render annotated map texture for export
    func render() -> MTLTexture? {
        // set up dimensions for borderless map
        let oversampling = export.oversampling
        let width = Double(export.dimension*oversampling)
        var height = state.projection.height(width: width), shift = 0.0
        let thickness = width/ColorbarView.aspect
        if (colorbar) { height += 2.0*thickness; shift += thickness }
        if (colorbar && export.range) { height += thickness; shift += thickness/2.0 }
        let w = Int(width), h = Int(height), t = Int(thickness)
        
        // render map texture and annotate it if requested
        guard let texture = mapview?.image(width: w, height: h, shift: (0,shift)) else { return nil }
        let output = (oversampling > 1) ? IMGTexture(width: w/oversampling, height: h/oversampling) : texture
        
        if (colorbar && export.range) {
            let scale = " (\(state.transform.f.rawValue.lowercased()) scale)"
            let annotation = (state.transform.f != .none) ? annotation + scale : annotation
            annotate(texture, height: t, min: state.range.min, max: state.range.max, annotation: export.annotation ? annotation : nil, font: font.nsFont, color: color.cgColor, background: state.palette.bg.cgColor)
        }
        
        if (colorbar || oversampling > 1) {
            guard let command = metal.queue.makeCommandBuffer() else { return nil }
            
            // render colorbar and copy it in
            if (colorbar) {
                guard let bar = barview?.image(width: w, height: 2*t),
                      let encoder = command.makeBlitCommandEncoder() else { return nil }
                
                encoder.copy(from: bar, sourceSlice: 0, sourceLevel: 0,
                             sourceOrigin: MTLOriginMake(0,0,0), sourceSize: MTLSizeMake(w,2*t,1),
                             to: texture, destinationSlice: 0, destinationLevel: 0,
                             destinationOrigin: MTLOriginMake(0, export.range ? t : 0, 0))
                encoder.endEncoding()
            }
            
            // scale down oversampled texture
            if (oversampling > 1) {
                let scaler = MPSImageLanczosScale(device: metal.device)
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
        guard let url = url ?? showSavePanel(type: export.format.type) else { return }
        if let output = render() { saveAsImage(output, url: url, format: export.format) }
    }
}

// annotate bottom part of a texture with data range labels and (optionally) a string
func annotate(_ texture: MTLTexture, height h: Int, min: Double, max: Double, format: String = "%+.6g", annotation: String? = nil, font: NSFont? = nil, fontname: String = "SF Compact", color: CGColor? = nil, background: CGColor? = nil) {
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
    let size = CGFloat(h)/1.1, scaled = font?.withSize(size)
    let font = scaled ?? CTFontCreateWithName(fontname as CFString, size, nil)
    let attr: [NSAttributedString.Key : Any] = [.font: font, .foregroundColor: color ?? .black]
    
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
