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
    @AppStorage(viewFromInsideKey) var viewFromInside = true
    @AppStorage(lightingKey) var lighting = false
    @AppStorage(annotationFontKey) var font = FontPreference.defaultValue
    @AppStorage(annotationColorKey) var color = Color.defaultValue
    
    // behavior tab
    @AppStorage(keepStateKey) var keepState = StateMask()
    @AppStorage(copyStateKey) var copyState = StateMask()
    
    
    // performance tab
    @AppStorage(TextureFormat.key) var texture = TextureFormat.defaultValue
    @AppStorage(AntiAliasing.key) var aliasing = AntiAliasing.defaultValue
    @AppStorage(ProxySize.key) var proxy = ProxySize.defaultValue
    @State private var device = "default"
    
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
                        Toggle(" View from inside (enable for CMB)", isOn: $viewFromInside)
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
                    }.frame(width: 210)
                }.padding(corner).frame(width: 380).overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .tabItem { Label("Appearance", systemImage: "eye") }
            // behavior tab
            HStack {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Map navigation remembers...").font(.title3)
                        Group {
                            Toggle(" Projection", isOn: $keepState.projection)
                            Toggle(" Viewpoint", isOn: $keepState.view)
                            Toggle(" Color Scheme", isOn: $keepState.palette)
                            Toggle(" Map Transform", isOn: $keepState.transform)
                            Toggle(" Color Bar Range", isOn: $keepState.range)
                            Toggle(" Map Lighting", isOn: $keepState.light).disabled(!lighting)
                        }.padding(.leading, offset)
                    }
                    Button("Reset") { keepState = StateMask() }.padding(5)
                }
                .padding(corner).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    VStack(alignment: .leading) {
                        Text("Style copy & paste transfers...").font(.title3)
                        Group {
                            Toggle(" Projection", isOn: $copyState.projection)
                            Toggle(" Viewpoint", isOn: $copyState.view)
                            Toggle(" Color Scheme", isOn: $copyState.palette)
                            Toggle(" Map Transform", isOn: $copyState.transform)
                            Toggle(" Color Bar Range", isOn: $copyState.range)
                            Toggle(" Map Lighting", isOn: $copyState.light).disabled(!lighting)
                        }.padding(.leading, offset)
                    }
                    Button("Reset") { copyState = StateMask() }.padding(5)
                }
                .padding(corner).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .tabItem { Label("Behavior", systemImage: "flowchart") }
            // performance tab
            VStack {
                VStack {
                    Picker("GPU device:", selection: $device) {
                        Text("Default").tag("default")
                    }.frame(width: 220)
                    Text("Currently running on \(metal.device.name)").padding(10)
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
                        }.frame(width: 180)
                        Picker("", selection: $aliasing) {
                            ForEach(AntiAliasing.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }.frame(width: 160)
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
