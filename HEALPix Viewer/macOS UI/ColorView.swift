//
//  ColorView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import SwiftUI

struct ColorView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ColorToolbar: View {
    @Binding var colorscheme: ColorScheme
    
    @Binding var mincolor: Color
    @Binding var maxcolor: Color
    @Binding var nancolor: Color
    
    @Binding var bgcolor: Color
    
    var body: some View {
        HStack {
            Picker("Color Scheme:", selection: $colorscheme) {
                ForEach(ColorScheme.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 220)
            Spacer().frame(width: 30)
            ColorPicker("Min:", selection: $mincolor)
                .onChange(of: colorscheme) { value in mincolor = value.colormap.min }
            ColorPicker("Max:", selection: $maxcolor)
                .onChange(of: colorscheme) { value in maxcolor = value.colormap.max }
            ColorPicker("NaN:", selection: $nancolor)
            Spacer().frame(width: 30)
            ColorPicker("Background:", selection: $bgcolor)
        }
        .padding(.top, 10)
        .padding(.bottom, 9)
    }
}
