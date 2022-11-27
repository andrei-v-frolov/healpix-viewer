//
//  TransformView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-26.
//

import SwiftUI

struct TransformToolbar: View {
    @State private var transform: DataTransform = .defaultValue
    @State private var mu: Double = 0.0
    @State private var sigma: Double = 1.0
    
    @Binding var datamin: Double
    @Binding var datamax: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Picker("Transform:", selection: $transform) {
                ForEach(DataTransform.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 190)
            Spacer().frame(width: 30)
            Slider(value: $mu, in: datamin...datamax) { Text("μ:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(!transform.mu)
            TextField("μ", value: $mu, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing).focused($focus)
                .disabled(!transform.mu)
            Spacer().frame(width: 30)
            Slider(value: $sigma, in: 0.0...max(abs(datamin),abs(datamax))) { Text("σ:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(!transform.sigma)
            TextField("σ", value: $sigma, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing).focused($focus)
                .disabled(!transform.sigma)
        }
        .padding(.top, 11)
        .padding(.bottom, 11)
    }
}
