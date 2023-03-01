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

struct ViewMenus: Commands {
    // application defaults
    @AppStorage(Appearance.appStorage) var appearance = Appearance.defaultValue
    
    // render colorbar?
    @AppStorage(viewFromInsideKey) var viewFromInside = true
    @AppStorage(showColorBarKey) var showColorBar = false
    @AppStorage(lightingKey) var lightingEffects = false
    @AppStorage(cursorKey) var cursorReadout = false
    
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
            Toggle(isOn: $viewFromInside) {
                Text("View From Inside")
            }
            .keyboardShortcut("I", modifiers: [.option, .command])
            Toggle(isOn: $cursorReadout) {
                Text("Cursor Readout")
            }
            .keyboardShortcut("R", modifiers: [.option, .command])
            Toggle(isOn: $lightingEffects) {
                Text("Lighting Effects")
            }
            .keyboardShortcut("L", modifiers: [.option, .command])
            Divider()
            Toggle(isOn: $showColorBar) {
                Text("Show Color Bar")
            }
            .keyboardShortcut("C", modifiers: [.option, .command])
        }
    }
}

struct DataMenus: Commands {
    // data source and projection
    @AppStorage(DataSource.appStorage) var dataSource = DataSource.defaultValue
    @AppStorage(DataConvolution.appStorage) var convolution = DataConvolution.defaultValue
    @AppStorage(Projection.appStorage) var projection = Projection.defaultValue
    @AppStorage(Orientation.appStorage) var orientation = Orientation.defaultValue
    
    // colorbar properties
    @AppStorage(ColorScheme.appStorage) var colorScheme = ColorScheme.defaultValue
    @AppStorage(DataTransform.appStorage) var dataTransform = DataTransform.defaultValue
    
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
                    ForEach(DataConvolution.allCases, id: \.self) {
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
                ForEach([DataTransform.none], id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach(DataTransform.flatten, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach(DataTransform.cdf, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
        }
    }
}
