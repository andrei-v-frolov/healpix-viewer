//
//  MapView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-18.
//

import SwiftUI
import MetalKit

struct MapView: NSViewRepresentable {
    typealias NSViewType = ProjectedView
    var view = ProjectedView()
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        return view
    }
    
    func updateNSView(_ view: Self.NSViewType, context: Self.Context) {
    }
}

class ProjectedView: MTKView {
}
