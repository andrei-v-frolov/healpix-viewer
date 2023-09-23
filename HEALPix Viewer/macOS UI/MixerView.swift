//
//  MixerView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-12.
//

import SwiftUI
import MetalKit

// decorrelator state
struct Decorrelator: Equatable {
    var alpha: Double = 0.5
    var beta: Double = 0.5
    var avg = double3(0.0)
    var cov = double3x3(0.0)
}

// color mixer panel view
struct MixerView: View {
    @Binding var sidebar: Navigator
    @Binding var loaded: [MapData]
    var host: MapData
    @Binding var action: Action
    
    // nside is restricted to that of host map
    var nside: Int { host.data.nside }
    
    // color mixer inputs
    private struct Inputs: Equatable {
        var x: UUID? = nil
        var y: UUID? = nil
        var z: UUID? = nil
    }
    
    @State private var id = Inputs()
    
    // decorrelation strategy
    @State private var decorrelate = Decorrelator()
    
    // color primaries
    @AppStorage(Primaries.key) var primaries: Primaries = .defaultValue
    
    // color mixer and correlator
    private let mixer = ColorMixer()
    private let correlator = Correlator()
    
    // disclosure state
    @State private var expanded = (maps: true, decorrelate: true, primaries: false)
    
    // focus state
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            DisclosureGroup(isExpanded: $expanded.maps) {}
            label: { HStack { Spacer(); Text("Mix Data Channels").font(.title3); Spacer() } }
            .padding([.leading,.trailing], 10)
            if expanded.maps {
                Group {
                    Divider()
                    MapPicker(label: "Select channel 1", loaded: $loaded, selected: $id.x, nside: nside)
                    MapPicker(label: "Select channel 2", loaded: $loaded, selected: $id.y, nside: nside)
                    MapPicker(label: "Select channel 3", loaded: $loaded, selected: $id.z, nside: nside)
                }.labelsHidden()
            }
            Divider()
            DisclosureGroup(isExpanded: $expanded.decorrelate) {
                HStack {
                    Slider(value: $decorrelate.alpha, in: 0...1) { Text("⍺:") } onEditingChanged: { editing in focus = false }
                        .help("Amount of decorrelation applied")
                    TextField("⍺:", value: $decorrelate.alpha, formatter: TwoDigitNumber)
                        .frame(width: 35).multilineTextAlignment(.trailing).focused($focus)
                }.padding([.top,.bottom], 5)
                HStack {
                    Slider(value: $decorrelate.beta, in: 0...1) { Text("β:") } onEditingChanged: { editing in focus = false }
                        .help("Overall expansion around mean value")
                    TextField("β:", value: $decorrelate.beta, formatter: TwoDigitNumber)
                        .frame(width: 35).multilineTextAlignment(.trailing).focused($focus)
                }.padding(.bottom, 5)
                HStack {
                    Slider(value: $primaries.gamma, in: -2.0...2.0) { Text("ɣ:") } onEditingChanged: { editing in focus = false }
                        .help("Power law exponent applied when mixing colors")
                    TextField("ɣ:", value: $primaries.gamma, formatter: TwoDigitNumber)
                        .frame(width: 35).multilineTextAlignment(.trailing).focused($focus)
                }.padding(.bottom, 5)
                Toggle(isOn: $primaries.compress) { Text("compress gamut") }
                    .help("Avoid clipped and over-saturated colors")
            } label: { HStack { Spacer(); Text("Decorrelation").font(.title3); Spacer() } }
            .padding([.leading, .trailing], 10)
            Divider()
            DisclosureGroup(isExpanded: $expanded.primaries) {
                Picker("Strategy:", selection: $primaries.mode) {
                    ForEach(Mixing.allCases, id: \.self) {
                        Text($0.rawValue).tag($0).help($0.description)
                    }
                }.pickerStyle(.segmented).labelsHidden().padding([.top,.bottom], 5)
                HStack {
                    ColorPicker("R:", selection: $primaries.r, supportsOpacity: false)
                    ColorPicker("G:", selection: $primaries.g, supportsOpacity: false)
                    ColorPicker("B:", selection: $primaries.b, supportsOpacity: false)
                }
                HStack {
                    ColorPicker("Black Point:", selection: $primaries.black, supportsOpacity: false)
                    ColorPicker("White Point:", selection: $primaries.white, supportsOpacity: false).disabled(primaries.mode == .add)
                }
            } label: { HStack { Spacer(); Text("Color Primaries").font(.title3); Spacer() } }
            .padding([.leading, .trailing], 10).labelsHidden()
            Divider()
            HStack {
                Button { focus = false; primaries = .defaultValue; decorrelate.alpha = 0.5; decorrelate.beta = 0.5 } label: { Label("Reset", systemImage: "sparkles") }
                    .help("Reset to default settings")
                Button { withAnimation { sidebar = .list } } label: { Label("Done", systemImage: "checkmark") }
                    .help("Close color mixer view")
            }.padding([.leading,.trailing], 10).padding([.top,.bottom], 5)
        }
        .onAppear { id = Inputs(x: host.id, y: host.id, z: host.id) }
        .onDisappear { action = .redraw }
        .onChange(of: id) { value in correlate(); colorize() }
        .onChange(of: decorrelate) { value in colorize() }
        .onChange(of: primaries) { value in colorize() }
    }
    
    // compute average and covariance
    func correlate(_ x: MapData? = nil, _ y: MapData? = nil, _ z: MapData? = nil) {
        guard let x = x ?? loaded[id.x], let y = y ?? loaded[id.y], let z = z ?? loaded[id.z],
              let (avg,cov) = correlator.correlate(x.available, y.available, z.available) else { return }
        
        decorrelate.avg = avg
        decorrelate.cov = cov
    }
    
    // render false color map
    func colorize(_ x: MapData? = nil, _ y: MapData? = nil, _ z: MapData? = nil, primaries: Primaries? = nil) {
        guard let x = x ?? loaded[id.x], let y = y ?? loaded[id.y], let z = z ?? loaded[id.z] else { return }
        
        mixer.mix(x, y, z, decorrelate: decorrelate, primaries: primaries ?? self.primaries, nan: .gray, output: host.texture)
    }
}
