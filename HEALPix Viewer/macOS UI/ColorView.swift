//
//  ColorView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import SwiftUI

struct ColorToolbar: View {
    @Binding var palette: Palette
    
    var body: some View {
        HStack {
            Picker("Color Scheme:", selection: $palette.scheme) {
                ForEach(ColorScheme.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 220)
            Spacer().frame(width: 30)
            ColorPicker("Min:", selection: $palette.min)
            ColorPicker("Max:", selection: $palette.max)
            ColorPicker("NaN:", selection: $palette.nan)
            Spacer().frame(width: 30)
            ColorPicker("Background:", selection: $palette.bg)
        }
        .padding(.top, 10)
        .padding(.bottom, 9)
    }
}
