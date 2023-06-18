//
//  OrientationView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-25.
//

import SwiftUI

struct OrientationToolbar: View {
    @Binding var view: Viewpoint
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Slider(value: $view.lat, in: -90.0...90.0) { Text("Lat:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
            TextField("Latitude", value: $view.lat, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
            Spacer().frame(width: 30)
            Slider(value: $view.lon, in: -180.0...180.0) { Text("Lon:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
            TextField("Longitude", value: $view.lon, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
            Spacer().frame(width: 30)
            Slider(value: $view.az, in: -180.0...180.0) { Text("Az:") } onEditingChanged: { editing in focus = false }
                .frame(width: 160)
            TextField("Azimuth", value: $view.az, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing).focused($focus)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
    }
}
