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
    @Binding var format: ImageFormat
    @Binding var width: Int
    @Binding var oversampling: Int
    @Binding var withColorBar: Bool
    @Binding var withDataRange: Bool
    @Binding var withAnnotation: Bool
    @Binding var annotation: String
    @Binding var font: NSFont?
    @Binding var color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Image(systemName: "globe").font(.system(size: 64))
                Image(systemName: "arrow.down").font(.system(size: 48))
                Picker("", selection: $format) {
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
                    TextField("Width", value: $width, formatter: SizeFormatter)
                        .frame(width: 50)
                    Picker("@", selection: $oversampling) {
                        Text("1x").tag(1)
                        if (width*2 <= 16384) { Text("2x").tag(2) }
                        if (width*3 <= 16384) { Text("3x").tag(3) }
                        if (width*4 <= 16384) { Text("4x").tag(4) }
                    }
                    .frame(width: 70)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Toggle("Include colorbar", isOn: $withColorBar.animation())
                        Toggle("Include data limits", isOn: $withDataRange)
                            .disabled(!withColorBar)
                        Toggle("Include annotation", isOn: $withAnnotation)
                            .disabled(!withColorBar || !withDataRange)
                    }
                    Spacer()
                    ColorPicker("", selection: $color)
                        .disabled(!withColorBar || !withDataRange)
                        .opacity(!withColorBar || !withDataRange ? 0.1 : 1.0)
                }
                TextField("Annotation", text: $annotation)
                    .disabled(!withColorBar || !withDataRange || !withAnnotation)
                FontPicker(font: $font)
                    .disabled(!withColorBar || !withDataRange)
            }
            Spacer()
        }
    }
}
