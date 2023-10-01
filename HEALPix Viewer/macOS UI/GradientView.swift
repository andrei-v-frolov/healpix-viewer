//
//  GradientView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

import SwiftUI

// gradient manager window view
struct GradientManager: View {
    @StateObject var gradient = GradientCollection([.value,.defaultValue, GradientContainer("Test Gradient", colors: [.black,.clear,.red])]).observeChildren()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                GradientEditor(gradient: gradient.current, width: geometry.size.width-20.0)
                Divider()
                HStack {
                    GradientList(gradient: gradient, width: geometry.size.width/2.0-20.0)
                    Divider()
                    ColorList(gradient: gradient.current)
                }
            }
        }
        .frame(
            minWidth:  420, idealWidth:  420, maxWidth:  .infinity,
            minHeight: 280, idealHeight: 600, maxHeight: .infinity
        )
    }
}

// gradient editor view
struct GradientEditor: View {
    @ObservedObject var gradient: GradientContainer
    @State private var barview: ColorbarView? = nil
    
    // gradient width
    var width = 400.0
    
    var body: some View {
        VStack {
            let nominal = width/ColorbarView.aspect, height = min(2.0*nominal, 25), thickness = height/nominal
            TextField(value: $gradient.name, formatter: AnyText(), prompt: Text("Gradient Name")) { Text("Color") }
                .autocorrectionDisabled(true).multilineTextAlignment(.leading).textFieldStyle(.roundedBorder)
                .frame(width: width).padding([.leading,.trailing,.top], 5)
            BarView(colorbar: .constant(gradient.colormap(256).texture), background: .constant(.clear),
                    barview: $barview, thickness: thickness, padding: 0.0, grid: true)
                .frame(height: height).padding([.leading,.trailing,.bottom], 5)
        }
    }
}

// gradient selection view
struct GradientRow: View {
    @ObservedObject var gradient: GradientContainer
    @State private var barview: ColorbarView? = nil
    
    // gradient width
    var width = 200.0
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            //image(gradient.preview)?.resizable()
            let nominal = width/ColorbarView.aspect, height = min(2.0*nominal, 15), thickness = height/nominal
            BarView(colorbar: .constant(gradient.colormap(16).texture), background: .constant(.clear),
                    barview: $barview, thickness: thickness, padding: 0.0, grid: true).frame(height: height)
            Text(gradient.name).font(.footnote)
        }
    }
}

// gradient list view
struct GradientList: View {
    @ObservedObject var gradient: GradientCollection
    
    // gradient width
    var width = 200.0
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *), let selected = gradient.selected {
                let binding = Binding { selected } set: { gradient.selected = $0 }
                List($gradient.list, editActions: .move, selection: binding) { $grad in GradientRow(gradient: grad, width: width) }
            } else {
                List(gradient.list, selection: $gradient.selected) { grad in GradientRow(gradient: grad, width: width) }
            }
            HStack {
                Button {
                    withAnimation { _ = gradient.insert(after: gradient.selected) }
                } label: {
                    Label("New", systemImage: "plus")
                }
                .help("Add new gradient definition")
                Button(role: .destructive) {
                    withAnimation { gradient.remove(gradient.selected) }
                } label: {
                    Label("Remove", systemImage: "xmark")
                }.disabled(gradient.selected == nil || gradient.list.count < 2)
                    .help("Remove gradient definition")
            }.padding([.leading,.trailing,.bottom], 10)
        }
        //.task { for g in gradients { DispatchQueue.main.async { preview(g) } } }
    }
    
    func preview(_ gradient: GradientContainer) {
        //guard let barview = barview else { return }
        //barview.render(from: gradient.colormap(64).texture, to: gradient.preview)
    }
}

// color anchor editor view
struct ColorRow: View {
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
    }
}

// gradient color list view
struct ColorList: View {
    @ObservedObject var gradient: GradientContainer
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *), let selected = gradient.selected {
                let binding = Binding { selected } set: { gradient.selected = $0 }
                List($gradient.anchors, editActions: .move, selection: binding) { $anchor in ColorRow(anchor: anchor) }
            } else {
                List(gradient.anchors, selection: $gradient.selected) { anchor in ColorRow(anchor: anchor) }
            }
            HStack {
                Button {
                    withAnimation { _ = gradient.insert(after: gradient.selected) }
                } label: {
                    Label("Add", systemImage: "plus")
                }
                    .help("Add color anchor")
                Button(role: .destructive) {
                    withAnimation { gradient.remove(gradient.selected) }
                } label: {
                    Label("Remove", systemImage: "xmark")
                }.disabled(gradient.selected == nil || gradient.anchors.count < 3)
                    .help("Remove color anchor")
            }.padding([.leading,.trailing,.bottom], 10)
        }
    }
}
