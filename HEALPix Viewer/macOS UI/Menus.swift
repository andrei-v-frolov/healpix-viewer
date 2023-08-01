//
//  Menus.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

// variable signalling action
enum Action: Equatable {
    case none
    case open, save, redraw
    case random(RandomField)
    case copyStyle, pasteStyle, pasteView, pasteColor, pasteLight, pasteAll, resetAll
}

// open window is only available on masOS 13+
@available(macOS 13.0, *)
struct OpenFile: View {
    @Environment(\.openWindow) var openWindow
    @Binding var action: Action
    @Binding var new: Bool
    
    var body: some View {
        Button("Open File...") {
            if new { openWindow(id: mapWindowID) }; DispatchQueue.main.async { action = .open }
        }.keyboardShortcut("O", modifiers: [.command])
    }
}

@available(macOS 13.0, *)
struct AddGradient: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        Button("Add Scheme...") { openWindow(id: gradientWindowID) }
            .keyboardShortcut("G", modifiers: [.command])
    }
}

// file menu hierarchy
struct FileMenus: Commands {
    @Binding var action: Action
    @Binding var targeted: Bool

    var body: some Commands {
        CommandGroup(before: CommandGroupPlacement.newItem) {
            if #available(macOS 13.0, *) { OpenFile(action: $action, new: .constant(!targeted)) }
            else { Button("Open File...") { action = .open }.keyboardShortcut("O", modifiers: [.command]).disabled(!targeted) }
            Button("Export As...") { action = .save }.keyboardShortcut("S", modifiers: [.command]).disabled(!targeted)
            Divider()
        }
    }
}

// edit menu hierarchy
struct EditMenus: Commands {
    @Binding var action: Action
    @Binding var targeted: Bool
    @AppStorage(lightingKey) var lighting = false
    
    var body: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.pasteboard) {
            Button("Copy Style") { action = .copyStyle }.keyboardShortcut("C", modifiers: [.command]).disabled(!targeted)
            Button("Paste Style") {action = .pasteStyle }.keyboardShortcut("V", modifiers: [.command]).disabled(!targeted)
            Button("Paste View") { action = .pasteView }.keyboardShortcut("V", modifiers: [.shift,.command]).disabled(!targeted)
            Button("Paste Color") { action = .pasteColor }.keyboardShortcut("C", modifiers: [.shift,.command]).disabled(!targeted)
            Button("Paste Light") { action = .pasteLight }.keyboardShortcut("L", modifiers: [.shift,.command])
                .disabled(!lighting || !targeted)
            Divider()
            Button("Paste All") { action = .pasteAll }.keyboardShortcut("V", modifiers: [.shift,.option,.command]).disabled(!targeted)
            Button("Reset All") { action = .resetAll }.keyboardShortcut("R", modifiers: [.command]).disabled(!targeted)
            Divider()
        }
    }
}

// view menu hierarchy
struct ViewMenus: Commands {
    @Binding var action: Action
    @Binding var targeted: Bool
    
    // application appearance
    @AppStorage(Appearance.key) var appearance = Appearance.defaultValue
    @AppStorage(Thumbnails.key) var thumbnails = Thumbnails.defaultValue
    
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
            Picker("Thumbnails", selection: $thumbnails) {
                ForEach(Thumbnails.allCases, id: \.self) {
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
            Button(colorbar ? "Hide Color Bar" : "Show Color Bar") { colorbar = !colorbar }
            .keyboardShortcut("B", modifiers: [.option, .command]).disabled(!targeted)
        }
    }
}

// data menu hierarchy
struct DataMenus: Commands {
    @Binding var action: Action
    @Binding var targeted: Bool
    
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
                }
                Menu("Generate") {
                    ForEach(RandomField.allCases, id: \.self) { pdf in
                        Button(pdf.rawValue + " Random Field") { action = .random(pdf) }
                    }
                }.disabled(!targeted)
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
            Divider()
            Group {
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(ColorScheme.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                if #available(macOS 13.0, *) { AddGradient() }
            }
        }
    }
}
