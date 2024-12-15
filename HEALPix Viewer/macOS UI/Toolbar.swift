//
//  Toolbar.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct Toolbar: CustomizableToolbarContent {
    @Binding var sidebar: Navigator
    @Binding var toolbar: ShowToolbar
    @Binding var overlay: ShowOverlay
    @Binding var colorbar: Bool
    @Binding var lighting: Bool
    @Binding var magnification: Double
    @Binding var cdf: [Double]?
    @Binding var info: String?
    
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: "toggleSidebar", placement: .navigation, showsByDefault: true) {
            Button {
                toggleSidebar()
            } label: {
                Label("Maps", systemImage: "sidebar.left")
            }
            .help("Toggle Sidebar")
        }
        Group {
            ToolbarItem(id: "projection", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleToolbar(.projection) }
                } label: {
                    Label("Projection", systemImage: "globe")
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
                    Label("View", systemImage: "rotate.3d")
                }
                .help("View Orientation")
            }
            ToolbarItem(id: "color", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleToolbar(.color) }
                } label: {
                    Label("Colors", systemImage: "paintpalette")
                }
                .help("Color Scheme")
                .disabled(sidebar == .mixer)
            }
            ToolbarItem(id: "transform", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleToolbar(.transform) }
                } label: {
                    Label("Transform", systemImage: "function")
                }
                .help("Data Transform")
                .disabled(sidebar == .mixer)
            }
            ToolbarItem(id: "range", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleColorbar() }
                } label: {
                    Label("Range", systemImage: "ruler")
                }
                .help("Colorbar & Range")
                .disabled(sidebar == .mixer)
            }
            ToolbarItem(id: "lighting", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleToolbar(.lighting) }
                } label: {
                    Label("Light", systemImage: "sun.max")
                }
                .help("Lighting Effects")
                .disabled(!lighting)
            }
        }
        Group {
            ToolbarItem(id: "statistics", placement: .automatic, showsByDefault: true) {
                if #available(macOS 13.0, *) {
                    Button {
                        toggleStatView()
                    } label: {
                        Label { Text("Stats") } icon: { Curve.gaussian.frame(width: 20, height: 24) }
                    }
                    .help("Data Statistics")
                    .disabled(cdf == nil || sidebar == .mixer)
                }
            }
            ToolbarItem(id: "info", placement: .automatic, showsByDefault: true) {
                Button {
                    toggleInfoView()
                } label: {
                    Label("Info", systemImage: "info.circle")
                }
                .help("HEALPix Header")
                .disabled(info == nil)
            }
        }
    }
    
    func toggleToolbar(_ bar: ShowToolbar) {
        toolbar = (toolbar == bar && overlay == .none) ? .none : bar; overlay = .none
    }
    
    func toggleColorbar() {
        colorbar = (overlay == .none) ? !colorbar : true; overlay = .none
    }
    
    func toggleStatView() {
        guard (cdf != nil) else { return }
        let new: ShowOverlay = (overlay == .statview) ? .none : .statview
        if overlay == .infoview { overlay = new } else { withAnimation { overlay = new } }
    }
    
    func toggleInfoView() {
        guard (info != nil) else { return }
        let new: ShowOverlay = (overlay == .infoview) ? .none : .infoview
        if overlay == .statview { overlay = new } else { withAnimation { overlay = new } }
    }
}

func toggleSidebar() {
    NSApp.keyWindow?.contentViewController?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)),
                                                         with: nil)
}

enum ShowToolbar {
    case none, projection, orientation, color, transform, lighting
}

enum ShowOverlay {
    case none, statview, infoview
}
