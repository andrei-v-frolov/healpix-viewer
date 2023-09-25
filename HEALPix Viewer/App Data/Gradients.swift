//
//  Gradients.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-09-24.
//

import SwiftUI

// ...
final class CustomGradients: ObservableObject {
    @Published var list: [GradientContainer]
    
    init(_ list: [GradientContainer]) { self.list = list }
}

// container of color anchors for gradient editor
final class GradientContainer: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    @Published var name: String
    @Published var anchors: [ColorAnchor]
    let preview = IMGTexture(width: 256, height: Int(512/ColorbarView.aspect))
    
    // retrieve gradient and colormap
    var colors: [Color] { anchors.map { $0.color } }
    var gradient: ColorGradient { ColorGradient(name: name, colors) ?? .defaultValue }
    func colormap(_ n: Int) -> ColorMap { ColorMap(lut: gradient.lut(n)) }
    
    // protocol implementation
    init(_ name: String, colors: [Color]) { self.name = name; anchors = colors.map { ColorAnchor($0) } }
    init(_ gradient: ColorGradient) { name = gradient.name; anchors = gradient.colors.map { ColorAnchor($0) } }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: GradientContainer, b: GradientContainer) -> Bool { a.id == b.id && a.anchors == b.anchors }
    
    // convenience wrappers
    func copy(to: GradientContainer) { to.name = name; to.anchors = anchors }
    func copy(from: GradientContainer) { name = from.name; anchors = from.anchors }
}

// color anchor for gradient editor
final class ColorAnchor: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    @Published var color: Color
    
    // protocol implementation
    init(_ color: Color) { self.color = color }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: ColorAnchor, b: ColorAnchor) -> Bool { a.id == b.id && a.color.hex == b.color.hex }
}
