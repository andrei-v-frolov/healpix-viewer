//
//  TransformView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-26.
//

import SwiftUI

struct TransformToolbar: View {
    @Binding var transform: DataTransform
    @Binding var mu: Double
    @Binding var sigma: Double
    
    @Binding var mumin: Double
    @Binding var mumax: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Picker("Transform:", selection: $transform) {
                ForEach([DataTransform.none], id: \.self) {
                    Text($0.formula).tag($0)
                }
                Divider()
                Group {
                    ForEach(DataTransform.flatten, id: \.self) {
                        Text($0.formula).tag($0)
                    }
                }
                Divider()
                Group {
                    ForEach(DataTransform.cdf, id: \.self) {
                        Text($0.formula).tag($0)
                    }
                }
            }
            .frame(width: 190)
            Spacer().frame(width: 30)
            Slider(value: $mu, in: mumin...mumax) { Text("μ:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(!transform.mu)
            TextField("μ", value: $mu, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing).focused($focus)
                .disabled(!transform.mu)
            Spacer().frame(width: 30)
            Slider(value: $sigma, in: -10.0...10.0) { Text("log σ:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(!transform.sigma)
            TextField("σ", value: $sigma, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
                .disabled(!transform.sigma)
        }
        .padding(.top, 11)
        .padding(.bottom, 11)
    }
}
