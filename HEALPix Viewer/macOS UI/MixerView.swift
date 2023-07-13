//
//  MixerView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-12.
//

import SwiftUI

struct MixerView: View {
    @Binding var sidebar: Navigator
    
    var body: some View {
        VStack {
            Text("Mixer Settings")
            Spacer()
            Button {
                withAnimation { sidebar = .list }
            } label: {
                Label("Done", systemImage: "checkmark")
            }
            .help("Close color mixer view")
            .padding(10)
        }
    }
}
