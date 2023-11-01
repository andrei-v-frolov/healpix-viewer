//
//  HEALPix_ViewerApp.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

// asynchronous queues for user-initiated tasks
let userTaskQueue = DispatchQueue(label: "serial", qos: .userInitiated)
let analysisQueue = DispatchQueue(label: "analysis", qos: .userInitiated, attributes: [.concurrent])

// main application entry point
@main struct HEALPixViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // window stack, action requsts, and clipboard
    @State private var stack = [ProjectedView.ID]()
    @State private var action = Action.none
    @State private var clipboard = ViewState.value
    
    // most actions require available target
    private var targeted: Bool { stack.count > 0 }
    
    var body: some Scene {
        WindowGroup(id: mapWindowID) {
            ContentView(stack: $stack, clipboard: $clipboard, action: $action)
        } .commands {
            FileMenus(action: $action, targeted: .constant(targeted))
            EditMenus(action: $action, targeted: .constant(targeted))
            ViewMenus(action: $action, targeted: .constant(targeted))
            DataMenus(action: $action, targeted: .constant(targeted))
        }
        .onChange(of: action) { value in if (value != .none && !targeted) { action = .none } }
        if #available(macOS 13.0, *) {
            Window("Gradient Editor", id: gradientWindowID) { GradientManager() }
        }
        Settings { SettingsView() }
    }
    
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        UserDefaults.standard.register(defaults: defaults)
    }
    
    // application appearance
    let appearanceObserver = UserDefaultsObserver(key: Appearance.key) { old, new in
        guard let raw = new as? String, let mode = Appearance(rawValue: raw) else { return }
        
        NSApp.appearance = mode.appearance
    }
}

// AppDelegate handles lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.appearance = Appearance.value.appearance
    }
    func applicationWillTerminate(_ notification: Notification) {
        for url in tmpfiles { try? FileManager.default.removeItem(at: url) }
    }
}

// observer for UserDefaults changes
final class UserDefaultsObserver: NSObject {
    let key: String
    private var onChange: (Any, Any) -> Void
    private var dispatched: [NSKeyValueChangeKey: Any]? = nil
    
    init(key: String, onChange: @escaping (Any, Any) -> Void) {
        self.key = key; self.onChange = onChange; super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == key, let change = change, !(change as NSDictionary).isEqual(to: dispatched) else { return }
        onChange(change[.oldKey] as Any, change[.newKey] as Any); dispatched = change
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key, context: nil)
    }
}

// unique observer container for SwiftUI views
final class Observers {
    var registered = [String: UserDefaultsObserver]()
    
    func add(key: String, onChange: @escaping (Any, Any) -> Void) {
        registered.updateValue(UserDefaultsObserver(key: key, onChange: onChange), forKey: key)
    }
}
