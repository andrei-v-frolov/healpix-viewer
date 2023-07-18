//
//  MixerView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-12.
//

import SwiftUI
import MetalKit

struct MixerView: View {
    @Binding var loaded: [MapData]
    @Binding var host: UUID?
    
    // nside is restricted to that of host map
    var nside: Int { loaded.first(where: { $0.id == host })?.data.nside ?? 0 }
    
    // color mixer inputs
    @State private var x: UUID? = nil
    @State private var y: UUID? = nil
    @State private var z: UUID? = nil
    
    // decorrelation strategy
    @State private var decorrelate: Decorrelation = .defaultValue
    @State private var beta = 1.0
    
    // color primaries
    @AppStorage(Primaries.key) var primaries: Primaries = .defaultValue
    
    // color mixer and correlator
    private let mixer = ColorMixer()
    private let correlator = Correlator()
    
    // focus state
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            Group {
                Text("Mix Data Channels").font(.title3)
                Divider()
                MapPicker(label: "Select channel 1", loaded: $loaded, selected: $x, nside: nside).labelsHidden()
                MapPicker(label: "Select channel 2", loaded: $loaded, selected: $y, nside: nside).labelsHidden()
                MapPicker(label: "Select channel 3", loaded: $loaded, selected: $z, nside: nside).labelsHidden()
            }
            Divider()
            Group {
                Text("Decorrelation").font(.title3)
                Picker("Strategy:", selection: $decorrelate) {
                    ForEach(Decorrelation.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }.pickerStyle(.segmented).labelsHidden()
                HStack {
                    Slider(value: $beta, in: 0...1) { Text("β:").foregroundColor(decorrelate == .none ? .disabled : .primary) } onEditingChanged: { editing in focus = false }
                    TextField("β:", value: $beta, formatter: TwoDigitNumber)
                        .frame(width: 35).multilineTextAlignment(.trailing).focused($focus)
                }.padding(.bottom, 5).disabled(decorrelate == .none)
            }.padding([.leading, .trailing], 10)
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
            Button { focus = false; primaries = .defaultValue } label: { Label("Reset", systemImage: "sparkles") }
            Divider()
            Group {
                Text("Output Gamma").font(.title3)
                HStack {
                    Slider(value: $primaries.gamma, in: 0.25...4.0) { Text("ɣ:") } onEditingChanged: { editing in focus = false }
                    TextField("ɣ:", value: $primaries.gamma, formatter: TwoDigitNumber)
                        .frame(width: 35).multilineTextAlignment(.trailing).focused($focus)
                }.padding(.bottom, 5)
            }.padding([.leading, .trailing], 10)
            Divider()
        }
        .onAppear { x = host; y = host; z = host; colorize() }
        .onChange(of: x) { value in colorize() }
        .onChange(of: y) { value in colorize() }
        .onChange(of: z) { value in colorize() }
        .onChange(of: primaries) { value in colorize() }
    }
    
    func colorize(_ x: MapData? = nil, _ y: MapData? = nil, _ z: MapData? = nil, primaries: Primaries? = nil) {
        guard let x = x ?? loaded.first(where: { $0.id == self.x }),
              let y = y ?? loaded.first(where: { $0.id == self.y }),
              let z = z ?? loaded.first(where: { $0.id == self.z }),
              let texture = loaded.first(where: { $0.id == host })?.texture else { return }
        
        let primaries = primaries ?? self.primaries
        mixer.mix(x, y, z, primaries: primaries, nan: .gray, output: texture)
    }
}
