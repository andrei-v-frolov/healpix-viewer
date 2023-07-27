//
//  Navigation.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-17.
//

import SwiftUI

// map summary view
struct NavigationRow: View {
    @ObservedObject var map: MapData
    @AppStorage(Thumbnails.key) var thumbnails = Thumbnails.defaultValue
    
    var body: some View {
        HStack{
            if (thumbnails == .left) { image(map.preview, oversample: 6) }
            VStack {
                if (thumbnails == .large) { image(map.preview) }
                Text(map.name)
                Text(map.file).font(.footnote)
            }.frame(maxWidth: .infinity)
            if (thumbnails == .right) { image(map.preview, oversample: 6) }
        }
    }
}

// loaded maps view
struct NavigationList: View {
    @Binding var loaded: [MapData]
    @Binding var selected: UUID?
    @Binding var action: MenuAction
    
    func entry(_ map: MapData) -> some View {
        NavigationRow(map: map).contextMenu {
            VStack {
                Button(role: .destructive) {
                    selected = map.id; action = .save
                } label: {
                    Label("Export", systemImage: "square.and.arrow.down")
                }
                .help("Export rendered map")
                Button {
                    selected = map.id; action = .resetAll
                } label: {
                    Label("Reset", systemImage: "sparkles")
                }
                .help("Reset view settings")
                Divider()
                Button(role: .destructive) {
                    loaded.removeAll(where: { $0.id == map.id })
                } label: {
                    Label("Close", systemImage: "xmark")
                }
                .help("Remove loaded map")
            }
        }.labelStyle(.titleAndIcon)
    }
    
    var body: some View {
        if #available(macOS 13.0, *), let selected = selected {
            let binding = Binding { selected } set: { self.selected = $0 }
            List($loaded, editActions: .move, selection: binding) { $map in entry(map) }
        } else {
            List(loaded, selection: $selected) { map in entry(map) }
        }
    }
}

// map picker view
struct MapPicker: View {
    var label: String
    @Binding var loaded: [MapData]
    @Binding var selected: UUID?
    
    // nside filter
    var nside = 0
    
    // respond to thumbnail style chages
    @AppStorage(Thumbnails.key) var thumbnails = Thumbnails.defaultValue
    
    // workaround for Menu stripping enclosed view styling
    @MainActor @available(macOS 13.0, *)
    func rendered(_ map: MapData) -> NSImage? {
        let renderer = ImageRenderer(content: NavigationRow(map: map).frame(width: 210).padding(.leading,5))
        renderer.scale = NSApplication.shared.keyWindow?.backingScaleFactor ?? 2.0
        return renderer.nsImage
    }
    
    var body: some View {
        Menu {
            ForEach(loaded, id: \.self) { map in
                if (map.data.nside == nside || nside == 0) {
                    Button { selected = map.id } label: {
                        if #available(macOS 13.0, *), let entry = rendered(map) { Image(nsImage: entry) } else {
                            Label { Text(map.name) + Text("  [\(map.file)]").font(.footnote) } icon: { image(map.preview, oversample: 8)?.scaledToFit() }
                        }
                    }.labelStyle(.titleAndIcon)
                }
            }
        } label: {
            if let map = loaded.first(where: { $0.id == selected }) { NavigationRow(map: map) }
            else { Label(label, systemImage: "globe") }
        }.buttonStyle(.plain).padding(5)
    }
}

// navigator panels
enum Navigator {
    case list, mixer, ilc, convolution
}
