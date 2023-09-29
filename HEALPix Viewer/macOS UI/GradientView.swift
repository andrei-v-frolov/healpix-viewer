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
    
    // associated views
    @State private var barview: ColorbarView? = nil
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                let name = Binding { gradient.current.name } set: { gradient.current.name = $0 }
                TextField(value: name, formatter: AnyText(), prompt: Text("Gradient Name")) { Text("Color") }
                    .autocorrectionDisabled(true).multilineTextAlignment(.leading).textFieldStyle(.roundedBorder).frame(minWidth: 90)
                    .padding([.leading,.trailing], 0.05*geometry.size.width+3).padding(.top, 5)
                BarView(colorbar: .constant(gradient.current.colormap(256).texture),
                        background: .constant(.clear), barview: $barview, thickness: 2.0, grid: true)
                .frame(height: 2.0*geometry.size.width/ColorbarView.aspect).padding([.leading,.trailing,.bottom], 5)
                HStack {
                    GradientList(gradient: gradient)
                    Divider()
                    ColorList(gradient: gradient.current)
                }
            }
        }
        .frame(
            minWidth:  420, idealWidth:  420, maxWidth:  .infinity,
            minHeight: 265, idealHeight: 600, maxHeight: .infinity
        )
    }
}

// gradient selector view
struct GradientRow: View {
    @ObservedObject var gradient: GradientContainer
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            image(gradient.preview)?.resizable()
            Text(gradient.name).font(.footnote)
        }
    }
}

// gradient list view
struct GradientList: View {
    @ObservedObject var gradient: GradientCollection
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *), let selected = gradient.selected {
                let binding = Binding { selected } set: { gradient.selected = $0 }
                List($gradient.list, editActions: .move, selection: binding) { $grad in GradientRow(gradient: grad) }
            } else {
                List(gradient.list, selection: $gradient.selected) { grad in GradientRow(gradient: grad) }
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
