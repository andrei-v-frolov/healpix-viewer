//
//  Menus.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct FileMenus: Commands {
    // menu commands
    var body: some Commands {
        CommandGroup(before: CommandGroupPlacement.newItem) {
            Button(action: { print("try to open file...") }, label: { Text("Open File...") })
                .keyboardShortcut("O", modifiers: [.command])
            Divider()
        }
    }
}

struct ViewMenus: Commands {
    // application defaults
    @AppStorage(Appearance.appStorage) var appearance = Appearance.defaultValue
    
    // render colorbar?
    @AppStorage("showColorBar") var showColorBar = true
    @AppStorage("showDataBar") var showDataBar = false
    
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
            Toggle(isOn: $showColorBar) {
                Text("Show Color Bar")
            }
            Toggle(isOn: $showDataBar) {
                Text("Show Data Sidebar")
            }
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
                Picker("Source", selection: $dataSource) {
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
                    Divider()
                    ForEach(DataSource.special, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    ForEach([DataSource.channel], id: \.self) {
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
                Picker("Projection", selection: $projection) {
                    ForEach(Projection.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Button("View Point") {}
                    Button("Lighting") {}
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
            Divider()
            Group {
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Button("Below Minimum") {}
                    Button("Above Maximum") {}
                    Button("Invalid Data") {}
                    Divider()
                    Button("Background") {}
                }
                Picker("Data Range", selection: $boundsModifier) {
                    ForEach(BoundsModifier.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Picker("Transform", selection: $dataTransform) {
                    ForEach(DataTransform.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                    Divider()
                    Picker("Apply...", selection: $dataTransform) {
                        Text("After Convolving")
                        Text("Before Convolving")
                    }
                }
                Picker("Bounds", selection: $dataBounds) {
                    ForEach(DataBounds.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }
        }
    }
}
