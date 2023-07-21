//
//  GradientView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

import SwiftUI

struct GradientManager: View {
    @State private var grad = ColorGradient(name: "Test Gradient", [.black,.red])
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        ColorList()
    }
}

// color anchor for gradient editor
final class ColorAnchor: Identifiable, Hashable, Equatable, ObservableObject {
    // unique map id
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
                .autocorrectionDisabled(true).multilineTextAlignment(.leading).frame(width: 90)
        }
    }
}

struct ColorList: View {
    //@State private var grad = ColorGradient(name: "Test Gradient", [.black,.red])
    @State private var anchors = [ColorAnchor(.red), ColorAnchor(.blue)]
    @State private var selected: UUID? = nil
    
    // share focus state between lists
    @FocusState private var focus: Bool
    
    var body: some View {
        if #available(macOS 13.0, *), let selected = selected {
            let binding = Binding { selected } set: { self.selected = $0 }
            List($anchors, editActions: .move, selection: binding) { $anchor in ColorRow(anchor: anchor) }.focused($focus)
        } else {
            List(anchors, selection: $selected) { anchor in ColorRow(anchor: anchor) }.focused($focus)
        }
        Divider()
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
                withAnimation { anchors.removeAll(where: { $0.id == selected }) }
            } label: {
                Label("Remove", systemImage: "xmark")
            }.disabled(selected == nil || anchors.count < 3)
            .help("Remove color anchor")
        }.padding([.leading,.trailing,.bottom], 10)
    }
}
