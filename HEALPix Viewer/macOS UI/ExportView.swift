//
//  ExportView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-23.
//

import SwiftUI

struct DropView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.doc").font(.system(size: 64))
            Text("Drop HEALPix file to load it...")
        }
        .padding(20)
        .background(.ultraThinMaterial)
    }
}

struct ExportView: View {
    @Binding var settings: Export
    @Binding var colorbar: Bool
    @Binding var annotation: String
    @Binding var font: NSFont?
    @Binding var color: Color
    
    // show dimensions field?
    @State private var dimensions = false
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Image(systemName: "globe").font(.system(size: 64))
                Image(systemName: "arrow.down").font(.system(size: 48))
                Picker("Image Format", selection: $settings.format) {
                    ForEach(ImageFormat.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }.labelsHidden().frame(width: 60)
            }
            Spacer(minLength: 20)
            VStack(alignment: .leading) {
                HStack {
                    Picker("Prefer", selection: $settings.prefer) {
                        ForEach(PreferredSize.specified, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredSize.fits, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredSize.widths, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredSize.heights, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.labelsHidden().frame(width: 120)
                    .onChange(of: settings.prefer) { value in withAnimation { dimensions = value.specific } }
                    if (dimensions) {
                        TextField("Dimension", value: $settings.dimension, formatter: SizeFormatter).frame(width: 50)
                    }
                    Picker("@", selection: $settings.oversampling) {
                        Text("1x").tag(1)
                        if (settings.dimension*2 <= maxTextureSize) { Text("2x").tag(2) }
                        if (settings.dimension*3 <= maxTextureSize) { Text("3x").tag(3) }
                        if (settings.dimension*4 <= maxTextureSize) { Text("4x").tag(4) }
                    }.labelsHidden().frame(width: 50)
                }.frame(height: 24)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Toggle("Include colorbar", isOn: $settings.colorbar)
                            .onChange(of: settings.colorbar) { value in withAnimation { colorbar ||= value } }
                        Toggle("Include data limits", isOn: $settings.range)
                            .disabled(!settings.colorbar)
                        Toggle("Include annotation", isOn: $settings.annotation)
                            .disabled(!settings.colorbar || !settings.range)
                    }
                    Spacer()
                    ColorPicker("", selection: $color)
                        .disabled(!settings.colorbar || !settings.range)
                        .opacity(!settings.colorbar || !settings.range ? 0.1 : 1.0)
                }
                TextField("Annotation", text: $annotation)
                    .disabled(!settings.colorbar || !settings.range || !settings.annotation)
                FontPicker(font: $font)
                    .disabled(!settings.colorbar || !settings.range)
            }
            Spacer()
        }
        .onAppear { dimensions = settings.prefer.specific; withAnimation { colorbar ||= settings.colorbar } }
    }
}
