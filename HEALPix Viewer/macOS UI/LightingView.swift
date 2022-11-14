//
//  LightingView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import SwiftUI

struct LightingView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct LightingToolbar: View {
    @Binding var lightingLat: Double
    @Binding var lightingLon: Double
    @Binding var lightingAmt: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Slider(value: $lightingLat, in: -90.0...90.0) { Text("Lat:") }.frame(width: 160)
                .onChange(of: lightingLat) { value in focus = false }
            TextField("Latitude", value: $lightingLat, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing)
                .focused($focus)
            Spacer().frame(width: 30)
            Slider(value: $lightingLon, in: -180.0...180.0) { Text("Lon:") }.frame(width: 160)
                .onChange(of: lightingLon) { value in focus = false }
            TextField("Longitude", value: $lightingLon, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing)
                .focused($focus)
            Spacer().frame(width: 30)
            Slider(value: $lightingAmt, in: 0.0...100.0) { Text("%:") }.frame(width: 160)
                .onChange(of: lightingAmt) { value in focus = false }
            TextField("Amount", value: $lightingAmt, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing)
                .focused($focus)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
    }
}
