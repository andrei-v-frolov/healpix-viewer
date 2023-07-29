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
    @Binding var host: UUID?
    
    // nside is restricted to that of host map
    var nside: Int { loaded.first(where: { $0.id == host })?.data.nside ?? 0 }
    
    // color mixer inputs
    private struct Inputs: Equatable {
        var x: UUID? = nil
        var y: UUID? = nil
        var z: UUID? = nil
    }
    
    @State private var id = Inputs()
    
    var body: some View {
        VStack {
            Group {
                Text("Component Separation").font(.title3)
                Divider()
                MapPicker(label: "Select channel 1", loaded: $loaded, selected: $id.x, nside: nside).labelsHidden()
                MapPicker(label: "Select channel 2", loaded: $loaded, selected: $id.y, nside: nside).labelsHidden()
                MapPicker(label: "Select channel 3", loaded: $loaded, selected: $id.z, nside: nside).labelsHidden()
            }
            Divider()
            HStack {
                Button { } label: { Label("Reset", systemImage: "sparkles") }
                    .help("Reset to default settings")
                Button { withAnimation { sidebar = .list } } label: { Label("Done", systemImage: "checkmark") }
                    .help("Close color mixer view")
            }.padding([.leading,.trailing], 10).padding([.top,.bottom], 5)
        }
        .onAppear { id = Inputs(x: host, y: host, z: host); print("APPEAR") }
    }
}
