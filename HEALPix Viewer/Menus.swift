//
//  Menus.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI

struct Menus: Commands {
    var body: some Commands {
        CommandMenu("Data") {
        }
        CommandMenu("Projection") {
        }
        CommandMenu("Color Bar") {
        }
        
        SidebarCommands()
        ToolbarCommands()
    }
}
