//
//  ProjectionView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-27.
//

import SwiftUI

struct ProjectionToolbar: View {
    @Binding var projection: Projection
    @Binding var orientation: Orientation
    @AppStorage(viewFromInsideKey) var inside: Bool = true
    
    var body: some View {
        HStack {
            Picker("Projection:", selection: $projection) {
                ForEach(Projection.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 190)
            Spacer().frame(width: 30)
            Picker("Viewpoint:", selection: $orientation) {
                ForEach(Orientation.galactic, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach(Orientation.ecliptic, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
                Divider()
                ForEach([Orientation.free], id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 190)
            Spacer().frame(width: 30)
            Picker("View From:", selection: $inside) {
                Text("Inside").tag(true)
                Text("Outside").tag(false)
            }
            .frame(width: 190)
        }
        .padding(.top, 11)
        .padding(.bottom, 11)
    }
}

