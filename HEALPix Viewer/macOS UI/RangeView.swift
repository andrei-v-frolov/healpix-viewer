//
//  RangeView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-08.
//

import SwiftUI

struct RangeView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct RangeToolbar: View {
    @State private var datamin: Double = -5.0
    @State private var datamax: Double = 13.0
    
    @State private var modifier: BoundsModifier = .defaultValue
    
    var body: some View {
        HStack {
            Spacer().frame(width: 20)
            TextField("Min", value: $datamin, formatter: TwoDigitNumber)
                .frame(width: 95).multilineTextAlignment(.trailing)
            Slider(value: $datamin, in: 0.0...1.0) {}.frame(width: 160)
            Spacer()
            Picker("Range:", selection: $modifier) {
                ForEach(BoundsModifier.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 150)
            Spacer()
            Slider(value: $datamax, in: 0.0...1.0) {}.frame(width: 160)
            TextField("Max", value: $datamax, formatter: TwoDigitNumber)
                .frame(width: 95).multilineTextAlignment(.trailing)
            Spacer().frame(width: 20)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
   }
}
