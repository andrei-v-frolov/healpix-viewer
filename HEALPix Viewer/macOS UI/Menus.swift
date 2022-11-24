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
            Button("Export To...") { if (NSApp.keyWindow != nil) { askToSave = true } }
                .keyboardShortcut("S", modifiers: [.command])
            Divider()
        }
    }
}

struct ViewMenus: Commands {
    // application defaults
    @AppStorage(Appearance.appStorage) var appearance = Appearance.defaultValue
    
    // render colorbar?
    @AppStorage(showColorBarKey) var showColorBar = false
    @AppStorage(showDataBarKey) var showDataBar = false
    @AppStorage(lightingKey) var lightingEffects = false
    
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
            Toggle(isOn: $lightingEffects) {
                Text("Lighting Effects")
            }
            .keyboardShortcut("L", modifiers: [.option, .command])
            Divider()
            Toggle(isOn: $showColorBar) {
                Text("Show Color Bar")
            }
            .keyboardShortcut("C", modifiers: [.option, .command])
            Toggle(isOn: $showDataBar) {
                Text("Show Data Sidebar")
            }
            .keyboardShortcut("D", modifiers: [.option, .command])
            .disabled(true)
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
    @AppStorage(DataBounds.appStorage) var dataBounds = DataBounds.defaultValue
    @AppStorage(BoundsModifier.appStorage) var boundsModifier = BoundsModifier.defaultValue
    
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
            }
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Divider()
                Group {
                Picker("Data Range", selection: $boundsModifier) {
                    ForEach(BoundsModifier.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .disabled(true)
                Picker("Transform", selection: $dataTransform) {
                    ForEach(DataTransform.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Picker("Apply...", selection: $dataTransform) {
                        Text("After Convolving")
                        Text("Before Convolving")
                    }
                    .disabled(true)
                }
                .disabled(true)
                Picker("Bounds", selection: $dataBounds) {
                    ForEach(DataBounds.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .disabled(true)
            }
        }
    }
}
