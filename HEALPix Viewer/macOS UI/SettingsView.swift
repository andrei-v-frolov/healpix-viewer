//
//  SettingsView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-13.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            // application color scheme
            // selectable annotation font
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .tabItem {
                    Label("Appearance", systemImage: "eye")
                }
            // option to drag the map with colorbar...
            // ===
            // copy and paste setting sets between loaded maps
            // keep colorbar and transform settings for each loaded map
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .tabItem {
                    Label("Behavior", systemImage: "flowchart")
                }
            // selectable GPU device (e.g. discrete/external unit)
            // selectable color texture precision (memory footprint)
            // proxy map to improve percieved transform performance
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .tabItem {
                    Label("Performance", systemImage: "speedometer")
                }
        }
        .frame(
            minWidth:  940, idealWidth: 1280, maxWidth:  .infinity,
            minHeight: 600, idealHeight: 800, maxHeight: .infinity
        )
    }
}
