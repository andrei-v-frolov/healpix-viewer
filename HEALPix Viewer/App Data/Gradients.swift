//
//  Gradients.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-09-24.
//

import SwiftUI
import Combine

// gradient collection for gradient editor
final class GradientCollection: ObservableObject {
    @Published var list: [GradientContainer]
    @Published var selected: UUID? = nil
    
    // reference pool to keep sinks from deallocation
    private var cancellables = [UUID: AnyCancellable]()
    
    // currently selected gradient
    var current: GradientContainer { return list[selected] ?? list.first ?? append() }
    
    // default initializer
    init(_ list: [GradientContainer]) { self.list = list.map { $0.observeChildren() } }
    deinit { for (_, sink) in cancellables { sink.cancel() } }
    
    // observation strategy
    func refresh() { self.objectWillChange.send() }
    
    func observe(_ element: GradientContainer) {
        guard cancellables[element.id] == nil else { return }
        cancellables[element.id] = element.objectWillChange.sink(receiveValue: { [weak self] _ in self?.refresh() })
    }
    
    func observeChildren() -> Self { list.forEach { observe($0) }; return self }
    
    // content management
    func remove(_ id: UUID?) {
        guard let id = id else { return }
        
        list.removeAll(where: { $0.id == id })
        cancellables.removeValue(forKey: id)
        if selected == id { selected = nil }
    }
    
    @discardableResult func insert(after id: UUID?, _ new: GradientContainer? = nil) -> GradientContainer {
        guard let i = list.firstIndex(where: { $0.id == id }) else { return append(new) }
        
        let new = (new ?? list[i].copy).observeChildren()
        list.insert(new, at: i+1); observe(new); selected = new.id; return new
    }
    
    @discardableResult func insert(before id: UUID?, _ new: GradientContainer? = nil) -> GradientContainer {
        guard let i = list.firstIndex(where: { $0.id == id }) else { return prepend(new) }
        
        let new = (new ?? list[i].copy).observeChildren()
        list.insert(new, at: i); observe(new); selected = new.id; return new
    }
    
    @discardableResult func append(_ new: GradientContainer? = nil) -> GradientContainer {
        let new = (new ?? list.last?.copy ?? .defaultValue).observeChildren()
        list.append(new); observe(new); selected = new.id; return new
    }
    
    @discardableResult func prepend(_ new: GradientContainer? = nil) -> GradientContainer {
        let new = (new ?? list.first?.copy ?? .defaultValue).observeChildren()
        list.insert(new, at: 0); observe(new); selected = new.id; return new
    }
}

extension GradientCollection: Codable, JsonRepresentable {
    enum CodingKeys: String, CodingKey { case gradients, selected }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let list = try container.decode([ColorGradient].self, forKey: .gradients)
        let name = try container.decode(String.self, forKey: .selected)
        
        self.init(list.map { GradientContainer($0) })
        self.selected = self.list.first(where: { $0.name == name})?.id
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(list.map { $0.gradient }, forKey: .gradients)
        try container.encode(current.name, forKey: .selected)
    }
}

// container of color anchors for gradient editor
final class GradientContainer: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    @Published var name: String
    @Published var anchors: [ColorAnchor]
    @Published var selected: UUID? = nil
    
    // reference pool to keep sinks from deallocation
    private var cancellables = [UUID: AnyCancellable]()
    
    // retrieve gradient and colormap
    var colors: [Color] { anchors.map { $0.color } }
    var gradient: ColorGradient { ColorGradient(name, colors: colors) ?? .defaultValue }
    func colormap(_ n: Int) -> ColorMap { ColorMap(lut: gradient.lut(n)) }
    
    // instance copy
    var copy: Self { Self(name+" Copy", colors: anchors.map { $0.color }) }
    
    // default initializers
    init(_ name: String, colors: [Color]) { self.name = name; anchors = colors.map { ColorAnchor($0) } }
    init(_ gradient: ColorGradient) { name = gradient.name; anchors = gradient.colors.map { ColorAnchor($0) } }
    deinit { for (_, sink) in cancellables { sink.cancel() } }
    
    // protocol implementation
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: GradientContainer, b: GradientContainer) -> Bool { a.id == b.id && a.anchors == b.anchors }
    
    // observation strategy
    func refresh() { self.objectWillChange.send() }
    
    func observe(_ element: ColorAnchor) {
        guard cancellables[element.id] == nil else { return }
        cancellables[element.id] = element.objectWillChange.sink(receiveValue: { [weak self] _ in self?.refresh() })
    }
    
    func observeChildren() -> Self { anchors.forEach { observe($0) }; return self }
    
    // content management
    func remove(_ id: UUID?) {
        guard let id = id else { return }
        
        anchors.removeAll(where: { $0.id == id })
        cancellables.removeValue(forKey: id)
        if selected == id { selected = nil }
    }
    
    @discardableResult func insert(after id: UUID?, _ new: ColorAnchor? = nil) -> ColorAnchor {
        guard let i = anchors.firstIndex(where: { $0.id == id }) else { return append(new) }
        
        let new = new ?? anchors[i].copy
        anchors.insert(new, at: i+1); observe(new); selected = new.id; return new
    }
    
    @discardableResult func insert(before id: UUID?, _ new: ColorAnchor? = nil) -> ColorAnchor {
        guard let i = anchors.firstIndex(where: { $0.id == id }) else { return prepend(new) }
        
        let new = new ?? anchors[i].copy
        anchors.insert(new, at: i); observe(new); selected = new.id; return new
    }
    
    @discardableResult func append(_ new: ColorAnchor? = nil) -> ColorAnchor {
        let new = new ?? anchors.last?.copy ?? ColorAnchor(.defaultValue)
        anchors.append(new); observe(new); selected = new.id; return new
    }
    
    @discardableResult func prepend(_ new: ColorAnchor? = nil) -> ColorAnchor {
        let new = new ?? anchors.first?.copy ?? ColorAnchor(.defaultValue)
        anchors.insert(new, at: 0); observe(new); selected = new.id; return new
    }
}

extension GradientContainer: RawRepresentable, Preference {
    convenience init?(rawValue: String) {
        guard let gradient = ColorGradient(rawValue: rawValue) else { return nil }
        self.init(gradient)
    }
    
    var rawValue: String { gradient.rawValue }
    
    // default values
    static let key = "gradient"
    static let defaultValue = GradientContainer(.defaultValue)
}

// color anchor for gradient editor
final class ColorAnchor: Identifiable, Hashable, Equatable, ObservableObject {
    let id = UUID()
    @Published var color: Color
    
    // instance copy
    var copy: Self { Self(color) }
    
    // protocol implementation
    init(_ color: Color) { self.color = color }
    func refresh() { self.objectWillChange.send() }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: ColorAnchor, b: ColorAnchor) -> Bool { a.id == b.id && a.color.hex == b.color.hex }
}
