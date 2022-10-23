//
//  Toolbar.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct Toolbar: CustomizableToolbarContent {
    @Binding var magnification: Double
    
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: "toggleSidebar", placement: .navigation, showsByDefault: true) {
            Button {
                toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .help("Toggle Sidebar")
        }
        ToolbarItem(id: "magnification", placement: .principal, showsByDefault: true) {
            Slider(value: $magnification, in: 0.0...10.0) {
                Text("Magnification")
            } minimumValueLabel: {
                Text("－")
            } maximumValueLabel: {
                Text("＋")
            }
            .frame(width: 160)
            .help("View Magnification")
        }
        ToolbarItem(id: "spacer", placement: .principal, showsByDefault: true) {
            Spacer()
        }
        ToolbarItem(id: "info", placement: .principal, showsByDefault: true) {
            Button {
                toggleSidebar()
            } label: {
                Image(systemName: "info.circle")
            }
            .help("Toggle Sidebar")
        }
    }
}

func toggleSidebar() {
    NSApp.keyWindow?.contentViewController?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)),
                                                         with: nil)
}
