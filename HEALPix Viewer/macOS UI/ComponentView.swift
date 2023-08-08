//
//  ComponentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-27.
//

import SwiftUI

struct UnitsView: View {
    @State private var f: Double = 100.0
    @State private var band: Frequency = .defaultValue
    @State private var units: Radiance = .defaultValue
    
    var body: some View {
        HStack {
            TextField("Frequency:", value: $f, formatter: TwoDigitNumber)
                .frame(width: 50).multilineTextAlignment(.trailing)
            Picker("Band Units:", selection: $band) {
                ForEach(Frequency.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }.frame(width: 60)
            Picker("Map Units:", selection: $units) {
                ForEach(Radiance.CMB, id: \.self) {
                    $0.label.tag($0)
                }
                Divider()
                ForEach(Radiance.RJ, id: \.self) {
                    $0.label.tag($0)
                }
                Divider()
                ForEach(Radiance.JY, id: \.self) {
                    $0.label.tag($0)
                }
            }.frame(width: 75)
        }.labelsHidden()
    }
}

struct ComponentView: View {
    @Binding var sidebar: Navigator
    @Binding var loaded: [MapData]
    @Binding var selected: UUID?
    @Binding var action: Action
    
    // nside is restricted to that of host map
    @State private var host: MapData? = nil
    
    // color mixer inputs
    private struct Inputs: Equatable {
        var x: UUID? = nil
        var y: UUID? = nil
        var z: UUID? = nil
    }
    
    @State private var id = Inputs()
    
    // component separator
    private let separator = ComponentSeparator()
    
    var body: some View {
        VStack {
            Group {
                Text("Component Separation").font(.title3)
                Divider()
                if let host = host {
                    let nside = host.data.nside, exclude = [host.id]
                    MapPicker(label: "Select channel 1", loaded: $loaded, selected: $id.x, nside: nside, exclude: exclude).labelsHidden()
                    MapPicker(label: "Select channel 2", loaded: $loaded, selected: $id.y, nside: nside, exclude: exclude).labelsHidden()
                    MapPicker(label: "Select channel 3", loaded: $loaded, selected: $id.z, nside: nside, exclude: exclude).labelsHidden()
                }
            }
            Divider()
            Group {
                Text("Map Frequencies").font(.title3)
                UnitsView()
                UnitsView()
                UnitsView()
            }
            Divider()
            Group {
                Text("Extract Based on...").font(.title3)
                //Picker("Strategy:", selection: $separate) {
                //    ForEach(Separation.allCases, id: \.self) {
                //        Text($0.rawValue).tag($0).help($0.description)
                //    }
                //}.pickerStyle(.segmented).labelsHidden().padding(.bottom, 5)
            }.padding([.leading, .trailing], 10)
            Divider()
            HStack {
                Button { } label: { Label("Reset", systemImage: "sparkles") }
                    .help("Reset to default settings")
                Button { withAnimation { sidebar = .list } } label: { Label("Done", systemImage: "checkmark") }
                    .help("Close component separation view")
            }.padding([.leading,.trailing], 10).padding([.top,.bottom], 5)
        }
        .onAppear() {
            if let like = loaded[selected] {
                host = component(nside: like.data.nside)
                id = Inputs(x: selected, y: selected, z: selected)
            }
        }
        .onChange(of: id) { value in ilc() }
    }
    
    // new map for separated component
    func component(nside: Int) -> MapData {
        guard let buffer = metal.device.makeBuffer(length: MemoryLayout<Float>.size*(12*nside*nside))
        else { fatalError("Could not allocate component buffer in component separator") }
        
        let map = GpuMap(nside: nside, buffer: buffer, min: -1.0, max: 1.0)
        return MapData(file: "extracted component", info: "", name: "PLACEHOLDER", unit: "", channel: 0, data: map)
    }
    
    // ...
    func ilc(_ map: MapData? = nil, x: MapData? = nil, y: MapData? = nil, z: MapData? = nil) {
        guard let map = map ?? host, let x = x ?? loaded[id.x], let y = y ?? loaded[id.y], let z = z ?? loaded[id.z] else { return }
        
        separator.extract(map.data, x: x.data, y: y.data, z: z.data)
        if (loaded[map.id] != nil) { action = .redraw } else { loaded.append(map); selected = map.id }
    }
}
