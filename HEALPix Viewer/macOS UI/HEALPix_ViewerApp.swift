//
//  HEALPix_ViewerApp.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

@main
struct HEALPix_ViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        } .commands {
            FileMenus()
            ViewMenus()
            DataMenus()
        }
    }
    
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    // application appearance
    let appearanceObserver = AppStorageObserver(key: Appearance.appStorage) { old, new in
        guard let raw = new as? String, let mode = Appearance(rawValue: raw) else { return }
        
        NSApp.appearance = mode.appearance
    }
}

// AppDelegate handles lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.appearance = Appearance.value.appearance
    }
}

// observer for UserDefaults changes
class AppStorageObserver: NSObject {
    let key: String
    private var onChange: (Any, Any) -> Void

    init(key: String, onChange: @escaping (Any, Any) -> Void) {
        self.key = key; self.onChange = onChange; super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change, object != nil, keyPath == key else { return }
        onChange(change[.oldKey] as Any, change[.newKey] as Any)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key, context: nil)
    }
}

// unique observer container for SwiftUI views
class Observers {
    var registered = [String: AppStorageObserver]()
    
    func add(key: String, onChange: @escaping (Any, Any) -> Void) {
        if registered[key] != nil { return }
        
        registered[key] = AppStorageObserver(key: key, onChange: onChange)
    }
}
