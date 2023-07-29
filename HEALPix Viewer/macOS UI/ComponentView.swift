//
//  ComponentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-27.
//

import SwiftUI

struct ComponentView: View {
    @Binding var sidebar: Navigator
    @Binding var loaded: [MapData]
    @Binding var host: UUID
    
    // nside is restricted to that of host map
    var nside: Int { loaded.first(where: { $0.id == host })?.data.nside ?? 0 }
    
    // color mixer inputs
    private struct Inputs: Equatable {
        var x: UUID? = nil
        var y: UUID? = nil
        var z: UUID? = nil
    }
    
    @State private var id = Inputs()
    
    // separation strategy
    @State private var separate = Separation.weights
    
    var body: some View {
        VStack {
            Group {
                Text("Component Separation").font(.title3)
                Divider()
                MapPicker(label: "Select channel 1", loaded: $loaded, selected: $id.x, nside: nside, exclude: [host]).labelsHidden()
                MapPicker(label: "Select channel 2", loaded: $loaded, selected: $id.y, nside: nside, exclude: [host]).labelsHidden()
                MapPicker(label: "Select channel 3", loaded: $loaded, selected: $id.z, nside: nside, exclude: [host]).labelsHidden()
            }
            Divider()
            Group {
                Text("Extract Based on...").font(.title3)
                Picker("Strategy:", selection: $separate) {
                    ForEach(Separation.allCases, id: \.self) {
                        Text($0.rawValue).tag($0).help($0.description)
                    }
                }.pickerStyle(.segmented).labelsHidden().padding(.bottom, 5)
            }.padding([.leading, .trailing], 10)
            Divider()
            HStack {
                Button { } label: { Label("Reset", systemImage: "sparkles") }
                    .help("Reset to default settings")
                Button { withAnimation { sidebar = .list } } label: { Label("Done", systemImage: "checkmark") }
                    .help("Close color mixer view")
            }.padding([.leading,.trailing], 10).padding([.top,.bottom], 5)
        }
        .onAppear {
            id = Inputs(x: host, y: host, z: host)
            let map = component(nside: nside)
            loaded.append(map); host = map.id
        }
    }
    
    // new component map
    func component(nside: Int) -> MapData {
        guard let buffer = metal.device.makeBuffer(length: MemoryLayout<Float>.size*(12*nside*nside))
        else { fatalError("Could not allocate component buffer in component separator") }
        
        let map = GpuMap(nside: nside, buffer: buffer, min: -1.0, max: 1.0)
        return MapData(file: "extracted component", info: "", name: "PLACEHOLDER", unit: "", channel: 0, data: map)
    }
}
