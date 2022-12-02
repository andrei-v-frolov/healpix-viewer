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
    @Binding var lighting: Bool
    @Binding var statview: Bool
    @Binding var infoview: Bool
    @Binding var magnification: Double
    @Binding var info: String?
    
    private let havecharts = {
        if #available(macOS 13.0, *) { return true } else { return false }
    }()
    
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: "toggleSidebar", placement: .navigation, showsByDefault: true) {
            Button {
                toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .help("Toggle Sidebar")
        }
        Group {
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
            ToolbarItem(id: "transform", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleToolbar(.transform) }
                } label: {
                    Image(systemName: "function")
                }
                .help("Data Transform")
            }
            ToolbarItem(id: "lighting", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleToolbar(.lighting) }
                } label: {
                    Image(systemName: "sun.max")
                }
                .help("Lighting Effects")
                .disabled(!lighting)
            }
        }
        ToolbarItem(id: "spacer", placement: .principal, showsByDefault: true) {
            Spacer()
        }
        Group {
            ToolbarItem(id: "statistics", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleStatView() }
                } label: {
                    Image(systemName: "waveform.path.ecg")
                }
                .help("Data Statistics")
                .disabled(false || !havecharts)
            }
            ToolbarItem(id: "info", placement: .principal, showsByDefault: true) {
                Button {
                    withAnimation { toggleInfoView() }
                } label: {
                    Image(systemName: "info.circle")
                }
                .help("HEALPix Header")
                .disabled(info == nil)
            }
        }
    }
    
    func toggleToolbar(_ bar: ShowToolbar) {
        toolbar = (toolbar == bar) ? .none : bar
    }
    
    func toggleColorbar() {
        colorbar = !colorbar
    }
    
    func toggleStatView() {
        statview = (!statview)
    }
    
    func toggleInfoView() {
        infoview = (!infoview) && (info != nil)
    }
}

func toggleSidebar() {
    NSApp.keyWindow?.contentViewController?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)),
                                                         with: nil)
}

enum ShowToolbar {
    case none, projection, orientation, color, transform, lighting
}
