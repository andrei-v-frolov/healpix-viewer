//
//  OrientationView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-25.
//

import SwiftUI

struct OrientationView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct OrientationToolbar: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var azimuth: Double
    
    var body: some View {
        HStack {
            Slider(value: $latitude, in: -90.0...90.0) { Text("Lat:") }.frame(width: 160)
            TextField("Latitude", value: $latitude, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing)
            Spacer().frame(width: 30)
            Slider(value: $longitude, in: -180.0...180.0) { Text("Lon:") }.frame(width: 160)
            TextField("Longitude", value: $longitude, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing)
            Spacer().frame(width: 30)
            Slider(value: $azimuth, in: -180.0...180.0) { Text("Az:") }.frame(width: 160)
            TextField("Azimuth", value: $azimuth, formatter: TwoDigitNumber)
                .frame(width: 55).multilineTextAlignment(.trailing)
        }
    }
}
