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
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Image(systemName: "globe").font(.system(size: 64))
                Image(systemName: "arrow.down").font(.system(size: 48))
                Picker("", selection: $settings.format) {
                    ForEach(ImageFormat.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }.frame(width: 70)
            }
            Spacer(minLength: 20)
            VStack(alignment: .leading) {
                HStack {
                    Text("Image width:")
                    Spacer(minLength: 10)
                    TextField("Width", value: $settings.dimension, formatter: SizeFormatter)
                        .frame(width: 50)
                    Picker("@", selection: $settings.oversampling) {
                        Text("1x").tag(1)
                        if (settings.dimension*2 <= 16384) { Text("2x").tag(2) }
                        if (settings.dimension*3 <= 16384) { Text("3x").tag(3) }
                        if (settings.dimension*4 <= 16384) { Text("4x").tag(4) }
                    }
                    .frame(width: 70)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Toggle("Include colorbar", isOn: $colorbar.animation())
                        Toggle("Include data limits", isOn: $settings.range)
                            .disabled(!colorbar)
                        Toggle("Include annotation", isOn: $settings.annotation)
                            .disabled(!colorbar || !settings.range)
                    }
                    Spacer()
                    ColorPicker("", selection: $color)
                        .disabled(!colorbar || !settings.range)
                        .opacity(!colorbar || !settings.range ? 0.1 : 1.0)
                }
                TextField("Annotation", text: $annotation)
                    .disabled(!colorbar || !settings.range || !settings.annotation)
                FontPicker(font: $font)
                    .disabled(!colorbar || !settings.range)
            }
            Spacer()
        }
    }
}
