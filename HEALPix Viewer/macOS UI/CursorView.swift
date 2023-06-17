//
//  CursorView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-03-01.
//

import SwiftUI

struct CursorView: View {
    @Binding var cursor: Cursor
    
    // number format for cursor readout
    private let format = "%+.8g°"
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Lat:")
                Text("Lon:")
            }
            VStack(alignment: .trailing) {
                Text(String(format: format, cursor.lat))
                Text(String(format: format, cursor.lon))
            }
            Spacer()
            if (cursor.pix >= 0) {
                VStack(alignment: .leading) {
                    Text("Pix:")
                    Text("Val:")
                }
                VStack(alignment: .trailing) {
                    Text(String(format: "%13i", cursor.pix))
                    Text(String(format: "%+.6E", cursor.val))
                }
            }
        }
        .padding(10)
        .font(Font.system(size: 13).monospaced())
    }
}
