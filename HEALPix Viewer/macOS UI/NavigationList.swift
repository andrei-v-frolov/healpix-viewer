//
//  NavigationList.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-17.
//

import SwiftUI

let lll = [
    MapLink(file: "xxx.fits", name: "TEMPERATURE"),
    MapLink(file: "xxx.fits", name: "POLARIZATION U"),
    MapLink(file: "xxx.fits", name: "POLARIZATION Q"),
]

struct MapLink: Hashable, Identifiable {
    let id = UUID()
    let file: String
    let name: String
}

struct NavigationRow: View {
    var map: MapLink
    
    var body: some View {
        HStack{
            VStack {
                Text(map.file)
                Text(map.name)
            }
            Spacer()
        }
    }
}

struct NavigationList: View {
    @Binding var selected: UUID?
    
    var body: some View {
        List(lll, selection: $selected) { map in NavigationRow(map: map) }
    }
}
