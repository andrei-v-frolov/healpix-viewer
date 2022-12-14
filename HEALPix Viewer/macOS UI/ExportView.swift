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
    @Binding var width: Int
    @Binding var oversampling: Int
    @Binding var withColorbar: Bool
    @Binding var withDatarange: Bool
    @Binding var withAnnotation: Bool
    @Binding var annotation: String
    
    let SizeFormatter = { var n = IntegerNumber; n.minimum = 0; n.maximum = 16384; return n }()
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "globe").font(.system(size: 64))
            Spacer(minLength: 20)
            VStack(alignment: .leading) {
                HStack {
                    Text("Image width:")
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
                Toggle("Include colorbar", isOn: $withColorbar.animation())
                Toggle("Include data limits", isOn: $withDatarange)
                    .disabled(!withColorbar)
                Toggle("Include annotation", isOn: $withAnnotation)
                    .disabled(!withColorbar || !withDatarange)
                TextField("Annotation", text: $annotation)
                    .frame(width: 215)
                    .disabled(!withColorbar || !withDatarange || !withAnnotation)
            }
            Spacer()
        }
    }
}
