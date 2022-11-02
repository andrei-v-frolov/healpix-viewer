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
    @State private var colorsheme: ColorScheme = .defaultValue
    
    @State private var mincolor = Color.blue
    @State private var maxcolor = Color.red
    @State private var nancolor = Color.green
    
    @State private var bgcolor = Color.black
    
    var body: some View {
        HStack {
            Picker("Color Scheme:", selection: $colorsheme) {
                ForEach(ColorScheme.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 210)
            Spacer().frame(width: 30)
            ColorPicker("Min:", selection: $mincolor)
            ColorPicker("Max:", selection: $maxcolor)
            ColorPicker("NaN:", selection: $nancolor)
            Spacer().frame(width: 30)
            ColorPicker("Background:", selection: $bgcolor)
        }
        .padding(.top, 13)
        .padding(.bottom, 3)
    }
}
