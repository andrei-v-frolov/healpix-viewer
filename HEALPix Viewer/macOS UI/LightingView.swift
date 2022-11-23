//
//  LightingView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import SwiftUI

struct LightingToolbar: View {
    @Binding var lightingLat: Double
    @Binding var lightingLon: Double
    @Binding var lightingAmt: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Slider(value: $lightingLat, in: -90.0...90.0) { Text("Lat:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
            TextField("Latitude", value: $lightingLat, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
            Spacer().frame(width: 30)
            Slider(value: $lightingLon, in: -180.0...180.0) { Text("Lon:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
            TextField("Longitude", value: $lightingLon, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
            Spacer().frame(width: 30)
            Slider(value: $lightingAmt, in: 0.0...100.0) { Text("%:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
            TextField("Amount", value: $lightingAmt, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
    }
}
