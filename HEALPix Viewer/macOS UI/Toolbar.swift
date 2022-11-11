//
//  Toolbar.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct Toolbar: CustomizableToolbarContent {
    @Binding var toolbar: ShowToolbar
    @Binding var colorbar: Bool
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
        ToolbarItem(id: "projection", placement: .principal, showsByDefault: true) {
            Button {
                withAnimation { toggleToolbar(.projection) }
            } label: {
                Image(systemName: "globe")
            }
            .help("Map Projection")
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
        ToolbarItem(id: "orientation", placement: .principal, showsByDefault: true) {
            Button {
                withAnimation { toggleToolbar(.orientation) }
            } label: {
                Image(systemName: "rotate.3d")
            }
            .help("View Orientation")
        }
        ToolbarItem(id: "color", placement: .principal, showsByDefault: true) {
            Button {
                withAnimation { toggleToolbar(.color) }
            } label: {
                Image(systemName: "paintpalette")
            }
            .help("Color Scheme")
        }
        ToolbarItem(id: "range", placement: .principal, showsByDefault: true) {
            Button {
                withAnimation { toggleColorbar() }
            } label: {
                Image(systemName: "ruler")
            }
            .help("Colorbar & Range")
        }
        ToolbarItem(id: "lighting", placement: .principal, showsByDefault: true) {
            Button {
                withAnimation { toggleToolbar(.lighting) }
            } label: {
                Image(systemName: "sun.max")
            }
            .help("Lighting Effects")
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
    
    func toggleToolbar(_ bar: ShowToolbar) {
        toolbar = (toolbar == bar) ? .none : bar
    }
    
    func toggleColorbar() {
        colorbar = !colorbar
    }
}

func toggleSidebar() {
    NSApp.keyWindow?.contentViewController?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)),
                                                         with: nil)
}

enum ShowToolbar {
    case none, projection, orientation, color, lighting
}
