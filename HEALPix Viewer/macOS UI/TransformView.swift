//
//  TransformView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-26.
//

import SwiftUI

struct TransformToolbar: View {
    @Binding var transform: Transform
    @Binding var ranked: Bool
    @Binding var mumin: Double
    @Binding var mumax: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Picker("Transform:", selection: $transform.f) {
                ForEach([Function.none], id: \.self) {
                    Text($0.formula).tag($0)
                }
                Divider()
                Group {
                    ForEach(Function.flatten, id: \.self) {
                        Text($0.formula).tag($0)
                    }
                }
                Divider()
                Group {
                    ForEach(Function.expand, id: \.self) {
                        Text($0.formula).tag($0)
                    }
                }
                Divider()
                Group {
                    ForEach(Function.cdf, id: \.self) {
                        if ranked { Text($0.formula).tag($0) } else { Text($0.formula).foregroundColor(.disabled).tag($0) }
                    }
                }
            }
            .frame(width: 190)
            Spacer().frame(width: 30)
            Slider(value: $transform.mu, in: mumin...mumax) { Text("μ:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(!transform.f.mu)
            TextField("μ", value: $transform.mu, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing).focused($focus)
                .disabled(!transform.f.mu)
            Spacer().frame(width: 30)
            Slider(value: $transform.sigma, in: transform.f.range) { Text("log σ:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(!transform.f.sigma)
            TextField("σ", value: $transform.sigma, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
                .disabled(!transform.f.sigma)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
    }
}
