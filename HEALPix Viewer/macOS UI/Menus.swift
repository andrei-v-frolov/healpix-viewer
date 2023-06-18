//
//  Menus.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct FileMenus: Commands {
    // variables signalling action
    @Binding var askToOpen: Bool
    @Binding var askToSave: Bool
    
    // menu commands
    var body: some Commands {
        CommandGroup(before: CommandGroupPlacement.newItem) {
            Button("Open File...") { if (NSApp.keyWindow != nil) { askToOpen = true } }
                .keyboardShortcut("O", modifiers: [.command])
            Button("Export As...") { if (NSApp.keyWindow != nil) { askToSave = true } }
                .keyboardShortcut("S", modifiers: [.command])
            Divider()
        }
    }
}

struct EditMenus: Commands {
    // menu commands
    var body: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.pasteboard) {
            Button("Copy Style") { }
                .keyboardShortcut("C", modifiers: [.command])
            Button("Paste Style") { }
                .keyboardShortcut("V", modifiers: [.command])
            Button("Paste View") { }
                .keyboardShortcut("V", modifiers: [.shift,.command])
            Button("Paste Color") { }
                .keyboardShortcut("C", modifiers: [.shift,.command])
            Button("Paste Light") { }
                .keyboardShortcut("L", modifiers: [.shift,.command])
            Divider()
            Button("Paste All") { }
                .keyboardShortcut("V", modifiers: [.shift,.option,.command])
            Divider()
        }
    }
}

struct ViewMenus: Commands {
    // application appearance
    @AppStorage(Appearance.key) var appearance = Appearance.defaultValue
    
    // render colorbar?
    @AppStorage(viewFromInsideKey) var viewFromInside = true
    @AppStorage(showColorBarKey) var colorbar = false
    @AppStorage(lightingKey) var lighting = false
    @AppStorage(cursorKey) var cursor = false
    @AppStorage(animateKey) var animate = true
    
    // menu commands
    var body: some Commands {
        Group {
            SidebarCommands()
            ToolbarCommands()
        }
        
        CommandGroup(before: CommandGroupPlacement.toolbar) {
            Picker("Appearance", selection: $appearance) {
                ForEach(Appearance.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            Divider()
            Toggle(isOn: $animate) {
                Text("Animate Rotation")
            }
            .keyboardShortcut("A", modifiers: [.option, .command])
            Toggle(isOn: $viewFromInside) {
                Text("View From Inside")
            }
            .keyboardShortcut("I", modifiers: [.option, .command])
            Toggle(isOn: $lighting) {
                Text("Lighting Effects")
            }
            .keyboardShortcut("L", modifiers: [.option, .command])
            Toggle(isOn: $cursor) {
                Text("Cursor Readout")
            }
            .keyboardShortcut("R", modifiers: [.option, .command])
            Divider()
            Toggle(isOn: $colorbar) {
                Text("Show Color Bar")
            }
            .keyboardShortcut("B", modifiers: [.option, .command])
        }
    }
}

struct DataMenus: Commands {
    // data source and projection
    @AppStorage(DataSource.key) var dataSource = DataSource.defaultValue
    @AppStorage(LineConvolution.key) var convolution = LineConvolution.defaultValue
    @AppStorage(Projection.key) var projection = Projection.defaultValue
    @AppStorage(Orientation.key) var orientation = Orientation.defaultValue
    
    // colorbar properties
    @AppStorage(ColorScheme.key) var colorScheme = ColorScheme.defaultValue
    @AppStorage(Function.key) var dataTransform = Function.defaultValue
    
    // menu commands
    var body: some Commands {
        CommandMenu("Data") {
            Group {
                Picker("Default Source", selection: $dataSource) {
                    ForEach(DataSource.temperature, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(DataSource.polarization, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(DataSource.vector, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Picker("Convolution", selection: $convolution) {
                    ForEach(LineConvolution.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Button("Kernel Length") {}
                }
                .disabled(true)
            }
            Divider()
            Group {
                Picker("Projection", selection: $projection) {
                    ForEach(Projection.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Picker("Orientation", selection: $orientation) {
                    ForEach(Orientation.galactic, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach(Orientation.ecliptic, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach([Orientation.free], id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }
            Divider()
            Picker("Transform", selection: $dataTransform) {
                ForEach([Function.none], id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach(Function.flatten, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach(Function.expand, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach(Function.cdf, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
        }
    }
}
