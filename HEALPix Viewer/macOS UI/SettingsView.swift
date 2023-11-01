//
//  SettingsView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-13.
//

import SwiftUI

struct SettingsView: View {
    // appearance tab
    @AppStorage(Appearance.key) var appearance = Appearance.defaultValue
    @AppStorage(Thumbnails.key) var thumbnails = Thumbnails.defaultValue
    @AppStorage(hdrKey) var hdr = true
    @AppStorage(animateKey) var animate = true
    @AppStorage(lightingKey) var lighting = false
    
    // behavior tab
    @AppStorage(keepStateKey) var keepState = StateMask.keep
    @AppStorage(copyStateKey) var copyState = StateMask.copy
    
    // export tab
    @AppStorage(dragSettingsKey) var drag = Export.drag
    @AppStorage(exportSettingsKey) var export = Export.save
    @AppStorage(annotationFontKey) var font = FontPreference.defaultValue
    @AppStorage(annotationColorKey) var color = Color.defaultValue
    
    // performance tab
    @AppStorage(PreferredGPU.key) var device = PreferredGPU.defaultValue
    @AppStorage(TextureFormat.key) var texture = TextureFormat.defaultValue
    @AppStorage(AntiAliasing.key) var aliasing = AntiAliasing.defaultValue
    @AppStorage(ProxySize.key) var proxy = ProxySize.defaultValue
    
    // view styling parameters
    private let width: CGFloat = 520
    private let height: CGFloat = 250
    private let corner: CGFloat = 7
    private let offset: CGFloat = 13
    
    var body: some View {
        TabView {
            // appearance tab
            VStack {
                VStack {
                    Picker("App Appearance:", selection: $appearance) {
                        ForEach(Appearance.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.frame(width: 230)
                    Picker("Map Thumbnails:", selection: $thumbnails) {
                        ForEach(Thumbnails.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.frame(width: 230)
                }.padding(corner).frame(width: 380).overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack(alignment: .leading) {
                    Text("When rendering the map...").font(.title3)
                    Group {
                        Toggle(" Render in HDR", isOn: $hdr)
                        Toggle(" Animate sphere rotation", isOn: $animate)
                        Toggle(" Apply lighting effects (sphere shading)", isOn: $lighting)
                    }.padding(.leading, offset)
                }.padding(corner).frame(width: 380, alignment: .center).overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    HStack {
                        Text("Annotation:")
                        FontPicker(font: $font.nsFont)
                        ColorPicker("", selection: $color)
                    }.frame(width: 340)
                }.padding(corner).frame(width: 380).overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .tabItem { Label("Appearance", systemImage: "eye") }
            // behavior tab
            HStack {
                StateMaskView(title: .constant("Map navigation remembers..."),
                              state: $keepState, defaults: .constant(StateMask.keep), lighting: $lighting)
                StateMaskView(title: .constant("Style copy & paste transfers..."),
                              state: $copyState, defaults: .constant(StateMask.copy), lighting: $lighting)
            }
            .tabItem { Label("Behavior", systemImage: "flowchart") }
            // export tab
            VStack {
                VStack {
                    ExportSettingsView(title: .constant("Drag & drop as:"),
                                   settings: $drag, defaults: .constant(Export.drag))
                    ExportSettingsView(title: .constant("Export as:"),
                                   settings: $export, defaults: .constant(Export.save))
                }
            }
            .tabItem { Label("Export", systemImage: "square.and.arrow.down") }
            // performance tab
            VStack {
                VStack {
                    Picker("Preferred GPU:", selection: $device) {
                        ForEach([PreferredGPU.system], id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredGPU.profiled, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredGPU.attached, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.frame(width: 220)
                    Text("Currently running on \(metal.device.name)").padding(.bottom, 5)
                    Text("Restart HEALPix Viewer to make GPU choice effective").font(.footnote)
                }.padding(corner).frame(width: 380).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    HStack {
                        Picker("Precision:", selection: $texture) {
                            ForEach(TextureFormat.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }.frame(width: 185)
                        Picker("Antialiasing", selection: $aliasing) {
                            ForEach(AntiAliasing.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }.labelsHidden().frame(width: 155)
                    }
                    Text("Balance render quality with memory footprint and performance").font(.footnote)
                }.padding(corner).frame(width: 380).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    Picker("Proxy map size:", selection: $proxy) {
                        ForEach(ProxySize.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.frame(width: 190).disabled(true)
                    Text("Increase responsiveness of parameter adjustments").font(.footnote)
                }.padding(corner).frame(width: 380).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .tabItem { Label("Performance", systemImage: "speedometer") }
        }
        .frame(
            minWidth:  width, idealWidth: width, maxWidth:  width,
            minHeight: height, idealHeight: height, maxHeight: height
        )
    }
}

struct StateMaskView: View {
    @Binding var title: String
    @Binding var state: StateMask
    @Binding var defaults: StateMask
    @Binding var lighting: Bool
    
    // view styling parameters
    private let corner: CGFloat = 7
    private let offset: CGFloat = 13
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(title).font(.title3)
                Group {
                    Toggle(" Projection", isOn: $state.projection)
                    Toggle(" Viewpoint", isOn: $state.view)
                    Toggle(" Color Scheme", isOn: $state.palette)
                    Toggle(" Map Transform", isOn: $state.transform)
                    Toggle(" Color Bar Range", isOn: $state.range)
                    Toggle(" Map Lighting", isOn: $state.light).disabled(!lighting)
                }.padding(.leading, offset)
            }
            Button("Reset") { state = defaults }.padding(5)
        }
        .padding(corner).overlay(
            RoundedRectangle(cornerRadius: corner)
            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ExportSettingsView: View {
    @Binding var title: String
    @Binding var settings: Export
    @Binding var defaults: Export
    
    // show dimensions field?
    @State private var dimensions = false
    
    // view styling parameters
    private let corner: CGFloat = 7
    private let offset: CGFloat = 13
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Picker("Image Format", selection: $settings.format) {
                    ForEach(ImageFormat.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }.labelsHidden().frame(width: 60)
                Picker("@", selection: $settings.oversampling) {
                    Text("1x").tag(1)
                    if (settings.dimension*2 <= maxTextureSize) { Text("2x").tag(2) }
                    if (settings.dimension*3 <= maxTextureSize) { Text("3x").tag(3) }
                    if (settings.dimension*4 <= maxTextureSize) { Text("4x").tag(4) }
                }.frame(width: 70)
                Text("oversampling")
            }.font(.title3)
            Group {
                HStack {
                    Picker("Prefer", selection: $settings.prefer) {
                        ForEach(PreferredSize.specified, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredSize.fits, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredSize.widths, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                        Divider()
                        ForEach(PreferredSize.heights, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.frame(width: 176)
                    .onChange(of: settings.prefer) { value in withAnimation { dimensions = value.specific } }
                    if (dimensions) {
                        TextField("Dimension", value: $settings.dimension, formatter: SizeFormatter).frame(width: 50)
                        Text("pixels")
                    }
                }.frame(height: 24)
            }.padding(.leading, offset)
            Group {
                HStack {
                    Text("Include")
                    Toggle("color bar", isOn: $settings.colorbar)
                    Toggle("range", isOn: $settings.range).disabled(!settings.colorbar)
                    Toggle("annotation", isOn: $settings.annotation).disabled(!settings.colorbar || !settings.range)
                    Spacer()
                    Button("Reset") { settings = defaults }
                }
            }.padding(.leading, offset)
        }
        .padding(corner).frame(width: 380).overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onAppear { dimensions = settings.prefer.specific }
    }
}
