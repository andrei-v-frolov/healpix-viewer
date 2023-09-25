//
//  GradientView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

import SwiftUI

// gradient manager window view
struct GradientManager: View {
    @ObservedObject var gradient = GradientContainer(.defaultValue)
    
    // associated views
    @State private var barview: ColorbarView? = nil
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                TextField(value: $gradient.name, formatter: AnyText(), prompt: Text("Gradient Name")) { Text("Color") }
                    .autocorrectionDisabled(true).multilineTextAlignment(.leading).textFieldStyle(.roundedBorder).frame(minWidth: 90)
                    .padding([.leading,.trailing], 0.05*geometry.size.width+3).padding(.top, 5)
                BarView(colorbar: .constant(gradient.colormap(256).texture),
                        background: .constant(.clear), barview: $barview, thickness: 2.0, grid: true)
                .frame(height: 2.0*geometry.size.width/ColorbarView.aspect).padding([.leading,.trailing,.bottom], 5)
                HStack {
                    //GradientList(current: $current, barview: $barview)
                    Divider()
                    ColorList(gradient: gradient)
                }
            }
        }
        .frame(
            minWidth:  420, idealWidth:  420, maxWidth:  .infinity,
            minHeight: 265, idealHeight: 600, maxHeight: .infinity
        )
    }
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
    
    init(_ name: String, colors: [Color]) { self.name = name; anchors = colors.map { ColorAnchor($0) } }
    init(_ gradient: ColorGradient) { name = gradient.name; anchors = gradient.colors.map { ColorAnchor($0) } }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: GradientContainer, b: GradientContainer) -> Bool { a.id == b.id && a.anchors == b.anchors }
}

// gradient selector view
struct GradientRow: View {
    @ObservedObject var container: GradientContainer
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            image(container.preview)?.resizable()
            Text(container.gradient.name).font(.footnote)
        }
    }
}

// gradient list view
struct GradientList: View {
    @State private var gradients = [GradientContainer(ColorGradient(name: "Test Gradient", [.black,.red])!)]
    @State private var selected: UUID? = nil
    @Binding var barview: ColorbarView?
    
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
        .onAppear { selected = gradients.first?.id }
        .task { for g in gradients { DispatchQueue.main.async { preview(g) } } }
    }
    
    func preview(_ gradient: GradientContainer) {
        guard let barview = barview else { return }
        barview.render(from: gradient.gradient.colormap(64).texture, to: gradient.preview)
        gradient.refresh()
    }
}

// color anchor for gradient editor
final class ColorAnchor: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    @Published var color: Color
    
    init(_ color: Color) { self.color = color }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: ColorAnchor, b: ColorAnchor) -> Bool { a.id == b.id && a.color.hex == b.color.hex }
}

// color anchor editor view
struct ColorRow: View {
    @ObservedObject var gradient: GradientContainer
    @ObservedObject var anchor: ColorAnchor
    
    // text input focus state
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack{
            let pick = Binding<Color> { anchor.color } set: { focus = false; anchor.color = $0 }
            let text = Binding<Color> { anchor.color } set: { if $0.hex != anchor.color.hex { anchor.color = $0 } }
            
            ColorPicker("Anchor:", selection: pick).labelsHidden().onHover { if $0 { focus = false } }
            TextField(value: text, formatter: ColorFormatter(), prompt: Text("Hex RGBA")) { Text("Color") }
                .autocorrectionDisabled(true).font(.body.monospaced()).textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.leading).focused($focus).frame(minWidth: 90)
            Menu {
                ForEach(named_colors, id: \.self) { name in
                    if let color = Color(name: name) {
                        Button { anchor.color = color } label: { Text("●  ").foregroundColor(color) + Text(name) }
                    }
                }
            } label: {}.menuStyle(.borderlessButton).frame(width: 10)
        }
        .onChange(of: anchor.color) { _ in gradient.refresh() }
    }
}

// gradient color list view
struct ColorList: View {
    @ObservedObject var gradient: GradientContainer
    @State private var selected: UUID? = nil
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *), let selected = selected {
                let binding = Binding { selected } set: { self.selected = $0 }
                List($gradient.anchors, editActions: .move, selection: binding) { $anchor in ColorRow(gradient: gradient, anchor: anchor) }
            } else {
                List(gradient.anchors, selection: $selected) { anchor in ColorRow(gradient: gradient, anchor: anchor) }
            }
            HStack {
                Button {
                    if let i = gradient.anchors.firstIndex(where: { $0.id == selected }) {
                        let new = ColorAnchor(gradient.anchors[i].color), k = min(i+1,gradient.anchors.endIndex)
                        withAnimation { gradient.anchors.insert(new, at: k); selected = new.id }
                    }
                } label: {
                    Label("Insert", systemImage: "plus")
                }.disabled(selected == nil)
                    .help("Insert color anchor")
                Button(role: .destructive) {
                    withAnimation { gradient.anchors.removeAll(where: { $0.id == selected }); selected = nil }
                } label: {
                    Label("Remove", systemImage: "xmark")
                }.disabled(selected == nil || gradient.anchors.count < 3)
                    .help("Remove color anchor")
            }.padding([.leading,.trailing,.bottom], 10)
        }
        .onAppear{ selected = anchors.first?.id }
    }
}
