//
//  MixerView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-12.
//

import SwiftUI

struct MixerView: View {
    @Binding var loaded: [MapData]
    @Binding var host: UUID?
    
    // nside restricted to that of host map
    var nside: Int { loaded.first(where: { $0.id == host })?.data.nside ?? 0 }
    
    // color mixer inputs
    @State private var a: UUID? = nil
    @State private var b: UUID? = nil
    @State private var c: UUID? = nil
    
    // optional transparency mask
    @State private var mask = false
    @State private var alpha: UUID? = nil
    
    // color primaries
    @AppStorage(Primaries.key) var primaries: Primaries = .defaultValue
    
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            Group {
                Text("Mix Data Channels").font(.title3)
                Divider()
                MapPicker(label: "Select channel 1", loaded: $loaded, selected: $a, nside: nside)
                MapPicker(label: "Select channel 2", loaded: $loaded, selected: $b, nside: nside)
                MapPicker(label: "Select channel 3", loaded: $loaded, selected: $c, nside: nside)
            }.labelsHidden()
            Divider()
            Group {
                Text("Color Primaries").font(.title3)
                HStack {
                    ColorPicker("R:", selection: $primaries.r)
                    ColorPicker("G:", selection: $primaries.g)
                    ColorPicker("B:", selection: $primaries.b)
                }
                HStack {
                    ColorPicker("Black Point:", selection: $primaries.black)
                    ColorPicker("White Point:", selection: $primaries.white)
                }
            }.labelsHidden()
            Divider()
            Group {
                Text("Output Gamma").font(.title3)
                HStack {
                    Slider(value: $primaries.gamma, in: 0.25...4.0) { Text("ɣ:") } onEditingChanged: { editing in focus = false }
                    TextField("ɣ:", value: $primaries.gamma, formatter: TwoDigitNumber)
                        .frame(width: 35).multilineTextAlignment(.trailing).focused($focus)
                }.padding([.leading, .trailing, .bottom], 10)
            }
            Divider()
            Group {
                Toggle(" Transparency Mask", isOn: $mask.animation()).font(.title3)
                if (mask) { MapPicker(label: "Select alpha mask", loaded: $loaded, selected: $alpha, nside: nside) }
            }
            Divider()
        }
        .onAppear { a = host; b = host; c = host }
    }
}
