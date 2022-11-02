//
//  ContentView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

// number formatter common to most fields
let TwoDigitNumber: NumberFormatter = {
    let format = NumberFormatter()
    
    format.minimumFractionDigits = 2
    format.maximumFractionDigits = 2
    
    return format
}()

// main window view
struct ContentView: View {
    @State private var toolbar = ShowToolbar.none
    
    @State private var projection: Projection = .defaultValue
    @State private var orientation: Orientation = .defaultValue
    @State private var spin: Bool = true
    
    @State private var magnification: Double = 0.0
    
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var azimuth: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
            }
            //ZStack(alignment: .top) {
            VStack {
                if (toolbar == .projection) {
                    ProjectionToolbar(projection: $projection, orientation: $orientation, spin: $spin)
                        .onChange(of: orientation) {
                            if ($0 != .free) {
                                let (lat,lon,az) = $0.coords
                                latitude = lat; longitude = lon; azimuth = az
                            }
                        }
                }
                if (toolbar == .orientation) {
                    OrientationToolbar(latitude: $latitude, longitude: $longitude, azimuth: $azimuth)
                        .onChange(of: latitude)  { value in orientation = .free }
                        .onChange(of: longitude) { value in orientation = .free }
                        .onChange(of: azimuth)   { value in orientation = .free }
                }
                if (toolbar == .color) {
                    ColorToolbar()
                }
                if (toolbar == .lighting) {
                    Text("Lighting Toolbar")
                }
                MapView(projection: $projection, magnification: $magnification, spin: $spin,
                        latitude: $latitude, longitude: $longitude, azimuth: $azimuth)
            }
        }
        .frame(
            minWidth:  800, idealWidth: 1280, maxWidth:  .infinity,
            minHeight: 600, idealHeight: 800, maxHeight: .infinity
        )
        .toolbar(id: "mainToolbar") {
            Toolbar(toolbar: $toolbar, magnification: $magnification)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
