//
//  ProjectionView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-27.
//

import SwiftUI

struct ProjectionView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ProjectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectionView()
    }
}

struct ProjectionToolbar: View {
    @Binding var projection: Projection
    @Binding var orientation: Orientation
    @Binding var spin: Bool
    
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
            Spacer().frame(width: 50)
            Toggle(" Spin to viewpoint", isOn: $spin)
        }
        .padding(.top, 11)
        .padding(.bottom, 4)
    }
}

