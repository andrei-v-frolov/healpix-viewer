//
//  SettingsView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-13.
//

import SwiftUI

struct SettingsView: View {
    // application color scheme
    @AppStorage(Appearance.key) var appearance = Appearance.defaultValue
    @AppStorage(viewFromInsideKey) var viewFromInside = true
    @AppStorage(lightingKey) var lightingEffects = false
    
    @AppStorage(textFontKey) var font = FontPreference.defaultValue
    @AppStorage(textColorKey) var color = Color.defaultValue
    
    @State private var separate: Bool = true
    
    @State private var bbb: Bool = true
    
    @State private var xxx = "CMB Viewer"
    
    // view styling parameters
    private let width: CGFloat = 520
    private let height: CGFloat = 250
    private let corner: CGFloat = 7
    private let offset: CGFloat = 13
    
    var body: some View {
        TabView {
            // application color scheme
            // selectable annotation font
            // option to drag the map with colorbar...
            Group {
                VStack {
                    VStack {
                        Picker("App Appearance:", selection: $appearance) {
                            ForEach(Appearance.allCases, id: \.self) {
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
                            Toggle(" Apply lighting effects (sphere shading)", isOn: $lightingEffects)
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
                        Toggle(" Drag & drop color bar separately", isOn: $separate)
                    }.padding(corner).frame(width: 380).overlay(
                        RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .tabItem { Label("Appearance", systemImage: "eye") }
            // copy and paste setting sets between loaded maps
            // keep colorbar and transform settings for each loaded map
            HStack {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Map navigation remembers...").font(.title3)
                        Group {
                            Toggle(" Projection", isOn: $bbb)
                            Toggle(" Viewpoint", isOn: $bbb)
                            Toggle(" Color Scheme", isOn: $bbb)
                            Toggle(" Map Transform", isOn: $bbb)
                            Toggle(" Color Bar Range", isOn: $bbb)
                            Toggle(" Map Lighting", isOn: $bbb).disabled(!lightingEffects)
                        }.padding(.leading, offset)
                    }
                    Button("Reset") {
                        bbb = true
                    }.padding(5)
                }
                .padding(corner).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    VStack(alignment: .leading) {
                        Text("Style copy & paste transfers...").font(.title3)
                        Group {
                            Toggle(" Projection", isOn: $bbb)
                            Toggle(" Viewpoint", isOn: $bbb)
                            Toggle(" Color Scheme", isOn: $bbb)
                            Toggle(" Map Transform", isOn: $bbb)
                            Toggle(" Color Bar Range", isOn: $bbb)
                            Toggle(" Map Lighting", isOn: $bbb).disabled(!lightingEffects)
                        }.padding(.leading, offset)
                    }
                    Button("Reset") {
                        bbb = true
                    }.padding(5)
                }
                .padding(corner).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .tabItem { Label("Behavior", systemImage: "flowchart") }
            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            // selectable GPU device (e.g. discrete/external unit)
            // selectable color texture precision (memory footprint)
            // proxy map to improve percieved transform performance
            VStack {
                VStack {
                    Picker("GPU device:", selection: $xxx) {
                        Text("Chocolate")
                        Text("Vanilla")
                        Text("Strawberry")
                    }.frame(width: 190)
                    Text("Currently running on XXX").padding(10)
                    Text("Restart HEALPix Viewer to make GPU choice effective").font(.footnote)
                }.padding(corner).frame(width: 320).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    Picker("Color precision:", selection: $xxx) {
                        Text("Chocolate")
                        Text("Vanilla")
                        Text("Strawberry")
                    }.frame(width: 190)
                    Text("Balance render quality with memory footprint").font(.footnote)
                }.padding(corner).frame(width: 320).overlay(
                    RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                VStack {
                    Picker("Proxy map size:", selection: $xxx) {
                        Text("Chocolate")
                        Text("Vanilla")
                        Text("Strawberry")
                        Divider()
                        Text("xxx")
                    }.frame(width: 190)
                    Text("Increase responsiveness of parameter adjustments").font(.footnote)
                }.padding(corner).frame(width: 320).overlay(
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