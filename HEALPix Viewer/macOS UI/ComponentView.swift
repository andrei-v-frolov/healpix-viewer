//
//  ComponentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-27.
//

import SwiftUI
import MetalKit

struct BandView: View {
    @Binding var map: MapBand
    
    var body: some View {
        HStack(spacing: 5) {
            TextField("Frequency:", value: $map.effective, formatter: OneDigitNumber)
                .frame(width: 45).multilineTextAlignment(.trailing)
                .help("Effective map frequency")
            Picker("Frequency Units:", selection: $map.frequency) {
                ForEach(Frequency.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }.frame(width: 60).help("Map frequency units")
            Picker("Map Units:", selection: $map.temperature) {
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
            }.frame(width: 75).help("Map units")
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
    
    // component separator inputs
    static private let mmaps = 9
    @State private var nmaps = 3
    @State private var id = [UUID?](repeating: nil, count: mmaps)
    @State private var band = [MapBand](repeating: MapBand(), count: mmaps)
    
    // component to extract and spectral model
    @State private var extract = Components.defaultValue
    @State private var model = SpectralModel()
    
    // component separator
    private let separator = ComponentSeparator()
    
    // disclosure state
    @State private var expanded = (maps: true, bands: true, extract: false, model: false)
    
    // focus state
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            DisclosureGroup(isExpanded: $expanded.maps) {
                Picker("#:", selection: $nmaps) {
                    ForEach([3,4,6,8,9], id: \.self) { Text(String($0)).tag($0) }
                }.pickerStyle(.segmented).labelsHidden().padding([.top,.bottom], 5)
                    .disabled(true)
            } label: { HStack { Spacer(); Text("Component Separation").font(.title3); Spacer() } }
            .padding([.leading,.trailing], 10)
            if let host = host, expanded.maps {
                let nside = host.data.nside, exclude = [host.id]
                Group {
                    Divider()
                    ForEach(0..<nmaps, id: \.self) {
                        MapPicker(label: "Select channel \($0)", loaded: $loaded, selected: $id[$0], nside: nside, exclude: exclude).labelsHidden()
                    }
                }
            }
            Divider()
            DisclosureGroup(isExpanded: $expanded.bands) {
                Group { ForEach(0..<nmaps, id: \.self) { BandView(map: $band[$0]) } }.padding(.top, 5)
            } label: { HStack { Spacer(); Text("Map Frequencies").font(.title3); Spacer() } }
            .padding([.leading,.trailing], 10)
            Divider()
            DisclosureGroup(isExpanded: $expanded.extract) {
                Picker("Component:", selection: $extract) {
                    ForEach(Components.allCases, id: \.self) {
                        Text($0.rawValue).tag($0).help($0.description)
                    }
                }.pickerStyle(.segmented).labelsHidden().padding([.top,.bottom], 5)
            } label: { HStack { Spacer(); Text("Extract \(expanded.extract ? "" : extract.rawValue)").font(.title3); Spacer() } }
            .padding([.leading, .trailing], 10)
            Divider()
            DisclosureGroup(isExpanded: $expanded.model) {
                HStack {
                    Slider(value: $model.alpha, in: (-5.6)...(-0.6)) { Text("α:") } onEditingChanged: { editing in focus = false }
                        .help("Low-frequency component power law")
                    TextField("α:", value: $model.alpha, formatter: TwoDigitNumber)
                        .frame(width: 45).multilineTextAlignment(.trailing).focused($focus)
                }.padding([.top,.bottom], 5)
                HStack {
                    Slider(value: $model.beta, in: 1.05...2.05) { Text("β:") } onEditingChanged: { editing in focus = false }
                        .help("Thermal dust emission power law")
                    TextField("β:", value: $model.beta, formatter: TwoDigitNumber)
                        .frame(width: 45).multilineTextAlignment(.trailing).focused($focus)
                }.padding(.bottom, 5)
                HStack {
                    Slider(value: $model.td, in: 4.5...34.5) { Text("T:") } onEditingChanged: { editing in focus = false }
                        .help("Thermal dust effective temperature")
                    TextField("T:", value: $model.td, formatter: TwoDigitNumber)
                        .frame(width: 45).multilineTextAlignment(.trailing).focused($focus)
                }.padding(.bottom, 5)
            } label: { HStack { Spacer(); Text("Spectral Model").font(.title3); Spacer() } }
            .padding([.leading, .trailing], 10)
            Divider()
            HStack {
                Button { model = SpectralModel() } label: { Label("Reset", systemImage: "sparkles") }
                    .help("Reset to default settings")
                Button { withAnimation { sidebar = .list } } label: { Label("Done", systemImage: "checkmark") }
                    .help("Close component separation view")
            }.padding([.leading,.trailing], 10).padding([.top,.bottom], 5)
        }
        .onAppear() {
            if let like = loaded[selected] {
                host = component(nside: like.data.nside)
                id = [UUID?](repeating: selected, count: Self.mmaps)
            }
        }
        .onChange(of: id) { [id] value in
            for i in 0..<nmaps { if value[i] != id[i], let map = loaded[value[i]] { lookup(&band[i], from: map) } }
            extract()
        }
    }
    
    // lookup frequency and units metadata (if available)
    func lookup(_ band: inout MapBand, from map: MapData) {
        // map frequency band
        if let v = map.card[.freq], case let .float(f) = v { band.nominal = Double(f) }
        if let v = map.card[.feff] ?? map.card[.freq], case let .float(f) = v { band.effective = Double(f) }
        if let v = map.card[.bandwidth], case let .float(f) = v { band.bandwidth = Double(f) }
        if let v = map.card[.funit], case let .string(s) = v, let u = Frequency(rawValue: s) { band.frequency = u }
        
        // map radiance units
        if let v = map.card[.temptype], case let .string(s) = v {
            switch s {
                case "THERMO":  if let u = Radiance(cmb: map.unit) { band.temperature = u }
                case "ANTENNA": if let u = Radiance(flux: map.unit) ?? Radiance(rj: map.unit) { band.temperature = u }
                default: break
            }
        }
        else if let u = Radiance(rawValue: map.unit) { band.temperature = u }
        else if let u = Radiance(cmb: map.unit) { band.temperature = u }
    }
    
    // new map for separated component
    func component(nside: Int) -> MapData {
        guard let buffer = metal.device.makeBuffer(length: MemoryLayout<Float>.size*(12*nside*nside))
        else { fatalError("Could not allocate component buffer in component separator") }
        
        let map = GpuMap(nside: nside, buffer: buffer, min: -1.0, max: 1.0)
        return MapData(file: "extracted component", info: "", parsed: Cards(), name: "PLACEHOLDER", unit: "", channel: 0, data: map)
    }
    
    // ...
    func extract(_ map: MapData? = nil, x: MapData? = nil, y: MapData? = nil, z: MapData? = nil) {
        guard let map = map ?? host, let x = x ?? loaded[id[0]], let y = y ?? loaded[id[1]], let z = z ?? loaded[id[2]] else { return }
        
        // temperature conversion factor
        let units = float3(band[0..<3].map { Float($0.gamma) })
        
        // spectral model
        let model = float3x3(
            float3(band[0..<3].map { Float(Components.lf.model($0.f, s: self.model)) }),
            float3(band[0..<3].map { Float(Components.cmb.model($0.f, s: self.model)) }),
            float3(band[0..<3].map { Float(Components.dust.model($0.f, s: self.model)) })
        )
        
        separator.extract(map.data, x: x.data, y: y.data, z: z.data, units: units, model: model)
        if (loaded[map.id] != nil) { action = .redraw } // else { loaded.append(map); selected = map.id }
    }
}
