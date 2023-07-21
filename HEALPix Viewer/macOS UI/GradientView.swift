//
//  GradientView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

import SwiftUI

// gradient manager window view
struct GradientManager: View {
    @State private var grad = ColorGradient(name: "Test Gradient", [.black,.red])
    @State private var palette = Palette()
    @State private var name = ""
    
    // associated views
    @State private var barview: ColorbarView? = nil
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                BarView(palette: $palette, barview: $barview)
                .frame(height: geometry.size.width/ColorbarView.aspect)
                .padding(5)
                TextField(value: $name, formatter: AnyText(), prompt: Text("Gradient Name")) { Text("Color") }
                    .autocorrectionDisabled(true).multilineTextAlignment(.leading).frame(minWidth: 90)
                    .padding([.leading,.trailing], 0.05*geometry.size.width+3)
                HStack {
                    GradientList()
                    Divider()
                    ColorList()
                }
            }
        }
        .frame(
            minWidth:  400, idealWidth:  400, maxWidth:  .infinity,
            minHeight: 245, idealHeight: 600, maxHeight: .infinity
        )
    }
}

// gradient container for gradient editor
final class GradientContainer: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    var gradient: ColorGradient
    
    init(_ gradient: ColorGradient) { self.gradient = gradient }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: GradientContainer, b: GradientContainer) -> Bool { a.id == b.id && a.gradient == b.gradient }
}

// gradient selector view
struct GradientRow: View {
    @ObservedObject var container: GradientContainer
    
    var body: some View {
        Text(container.gradient.name)
    }
}

// gradient list view
struct GradientList: View {
    @State private var gradients = [GradientContainer(ColorGradient(name: "Test Gradient", [.black,.red])!)]
    @State private var selected: UUID? = nil
    
    // share focus state between lists
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *), let selected = selected {
                let binding = Binding { selected } set: { self.selected = $0 }
                List($gradients, editActions: .move, selection: binding) { $grad in GradientRow(container: grad) }.focused($focus)
            } else {
                List(gradients, selection: $selected) { grad in GradientRow(container: grad) }.focused($focus)
            }
            HStack {
                Button {
                    if let i = gradients.firstIndex(where: { $0.id == selected }) {
                        withAnimation { gradients.insert(GradientContainer(gradients[i].gradient), at: min(i+1,gradients.endIndex)) }
                    } else {
                        withAnimation { gradients.append(GradientContainer(ColorGradient.defaultValue)) }
                    }
                } label: {
                    Label("New", systemImage: "plus")
                }
                .help("Add new gradient definition")
                Button(role: .destructive) {
                    withAnimation { gradients.removeAll(where: { $0.id == selected }); selected = nil }
                } label: {
                    Label("Remove", systemImage: "xmark")
                }.disabled(selected == nil)
                    .help("Remove gradient definition")
            }.padding([.leading,.trailing,.bottom], 10)
        }
    }
}

// color anchor for gradient editor
final class ColorAnchor: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    var color: Color
    
    init(_ color: Color) { self.color = color }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: ColorAnchor, b: ColorAnchor) -> Bool { a.id == b.id && a.color == b.color }
}

// color anchor editor view
struct ColorRow: View {
    @ObservedObject var anchor: ColorAnchor
    
    var body: some View {
        HStack{
            let color = Binding<Color> { anchor.color } set: { anchor.color = $0; anchor.refresh() }
            ColorPicker("Anchor:", selection: color).labelsHidden()
            TextField(value: color, formatter: ColorFormatter(), prompt: Text("Hex RGBA")) { Text("Color") }
                .autocorrectionDisabled(true).font(.body.monospaced())
                .multilineTextAlignment(.leading).frame(minWidth: 90)
        }
    }
}

// color list view
struct ColorList: View {
    @State private var anchors = [ColorAnchor(.red), ColorAnchor(.blue)]
    @State private var selected: UUID? = nil
    
    // share focus state between lists
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *), let selected = selected {
                let binding = Binding { selected } set: { self.selected = $0 }
                List($anchors, editActions: .move, selection: binding) { $anchor in ColorRow(anchor: anchor) }.focused($focus)
            } else {
                List(anchors, selection: $selected) { anchor in ColorRow(anchor: anchor) }.focused($focus)
            }
            HStack {
                Button {
                    if let i = anchors.firstIndex(where: { $0.id == selected }) {
                        withAnimation { anchors.insert(ColorAnchor(anchors[i].color), at: min(i+1,anchors.endIndex)) }
                    }
                } label: {
                    Label("Insert", systemImage: "plus")
                }.disabled(selected == nil)
                    .help("Insert color anchor")
                Button(role: .destructive) {
                    withAnimation { anchors.removeAll(where: { $0.id == selected }); selected = nil }
                } label: {
                    Label("Remove", systemImage: "xmark")
                }.disabled(selected == nil || anchors.count < 3)
                    .help("Remove color anchor")
            }.padding([.leading,.trailing,.bottom], 10)
        }
    }
}
