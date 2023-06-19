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
    @AppStorage(viewFromInsideKey) var viewFromInside = true
    @AppStorage(lightingKey) var lightingEffects = false
    @AppStorage(annotationFontKey) var font = FontPreference.defaultValue
    @AppStorage(annotationColorKey) var color = Color.defaultValue
    @AppStorage(dragWithColorBarKey) var dragColorBar = false
    @AppStorage(dragWithAnnotationKey) var dragAnnotation = false
    
    // behavior tab
    @AppStorage(keepProjectionKey) var keepProjection = false
    @AppStorage(keepViewpointKey) var keepViewpoint = false
    @AppStorage(keepColorSchemeKey) var keepColorScheme = true
    @AppStorage(keepMapTransformKey) var keepMapTransform = true
    @AppStorage(keepColorBarRangeKey) var keepColorBarRange = true
    @AppStorage(keepMapLightingKey) var keepMapLighting = false
    
    @AppStorage(copyProjectionKey) var copyProjection = true
    @AppStorage(copyViewpointKey) var copyViewpoint = true
    @AppStorage(copyColorSchemeKey) var copyColorScheme = true
    @AppStorage(copyMapTransformKey) var copyMapTransform = true
    @AppStorage(copyColorBarRangeKey) var copyColorBarRange = true
    @AppStorage(copyMapLightingKey) var copyMapLighting = false
    
    
    @State private var xxx = "CMB Viewer"
    
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
                    HStack {
                        Text("Drag & drop map with")
                        Toggle("color bar", isOn: $dragColorBar)
                        Toggle("annotation", isOn: $dragAnnotation).disabled(!dragColorBar)
                    }
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
                            Toggle(" Projection", isOn: $keepProjection)
                            Toggle(" Viewpoint", isOn: $keepViewpoint)
                            Toggle(" Color Scheme", isOn: $keepColorScheme)
                            Toggle(" Map Transform", isOn: $keepMapTransform)
                            Toggle(" Color Bar Range", isOn: $keepColorBarRange)
                            Toggle(" Map Lighting", isOn: $keepMapLighting).disabled(!lightingEffects)
                        }.padding(.leading, offset)
                    }
                    Button("Reset") {
                        keepProjection = false
                        keepViewpoint = false
                        keepColorScheme = true
                        keepMapTransform = true
                        keepColorBarRange = true
                        keepMapLighting = false
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
                            Toggle(" Projection", isOn: $copyProjection)
                            Toggle(" Viewpoint", isOn: $copyViewpoint)
                            Toggle(" Color Scheme", isOn: $copyColorScheme)
                            Toggle(" Map Transform", isOn: $copyMapTransform)
                            Toggle(" Color Bar Range", isOn: $copyColorBarRange)
                            Toggle(" Map Lighting", isOn: $copyMapLighting).disabled(!lightingEffects)
                        }.padding(.leading, offset)
                    }
                    Button("Reset") {
                        copyProjection = true
                        copyViewpoint = true
                        copyColorScheme = true
                        copyMapTransform = true
                        copyColorBarRange = true
                        copyMapLighting = false
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
