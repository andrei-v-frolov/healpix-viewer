//
//  NavigationList.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-17.
//

import SwiftUI

final class MapData: Identifiable, ObservableObject {
    // unique map id
    let id = UUID()
    
    // map metadata
    let file: String
    let info: String
    let name: String
    let unit: String
    let channel: Int
    
    // map data and caches
    let data: CpuMap
    var ranked: CpuMap? = nil
    var buffer: GpuMap? = nil
    
    var map: Map {
        switch state.f {
            case .none: return data
            case .equalize: return ranked ?? data
            default: return buffer ?? data
        }
    }
    
    // map preview
    let preview = IMGTexture(width: 96, height: 48)
    
    // saved view settings
    var settings = ViewState()
    
    // current transform state
    internal var state = Transform()
    
    // default initializer
    init(file: String, info: String, name: String, unit: String, channel: Int, map: CpuMap) {
        self.file = file
        self.info = info
        self.name = name
        self.unit = unit
        self.channel = channel
        self.data = map
    }
    
    // signal that map state changed
    func refresh() { self.objectWillChange.send() }
}

struct NavigationRow: View {
    @ObservedObject var map: MapData
    @AppStorage(Thumbnails.key) var thumbnails = Thumbnails.defaultValue
    
    var body: some View {
        HStack{
            if (thumbnails == .left) { image(map.preview) }
            VStack {
                Text(map.name)
                Text(map.file).font(.footnote)
            }.frame(maxWidth: .infinity)
            if (thumbnails == .right) { image(map.preview) }
        }
    }
}

struct NavigationList: View {
    @Binding var loaded: [MapData]
    @Binding var selected: UUID?
    
    var body: some View {
        List(loaded, selection: $selected) { map in NavigationRow(map: map) }
    }
}
