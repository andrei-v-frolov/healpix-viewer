//
//  ExportView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-23.
//

import SwiftUI

struct ExportView: View {
    @State private var width: Double = 1920
    @State private var oversampling: Int = 1
    @State private var colorbar: Bool = true
    @State private var datarange: Bool = true
    @State private var annotation: Bool = true
    @State private var units: String = "TEMPERATURE [μK]"
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "globe").font(.system(size: 64))
            Spacer(minLength: 20)
            VStack(alignment: .leading) {
                HStack {
                    Text("Image width:")
                    TextField("Width", value: $width, formatter: IntegerNumber)
                        .frame(width: 50)
                    Picker("@", selection: $oversampling) {
                        Text("1x").tag(1)
                        Text("2x").tag(2)
                        Text("3x").tag(3)
                        Text("4x").tag(4)
                    }
                    .frame(width: 70)
                }
                Toggle("Include colorbar", isOn: $colorbar)
                Toggle("Include data limits", isOn: $datarange)
                Toggle("Include annotation", isOn: $annotation)
                TextField("Annotation", text: $units)
                    .frame(width: 215)
                    .disabled(!annotation)
            }
            Spacer()
        }
    }
}
