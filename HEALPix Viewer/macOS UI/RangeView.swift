//
//  RangeView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-08.
//

import SwiftUI

struct RangeView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct RangeToolbar: View {
    @Binding var datamin: Double
    @Binding var datamax: Double
    
    @Binding var rangemin: Double
    @Binding var rangemax: Double
    
    @Binding var modifier: BoundsModifier
    
    var body: some View {
        HStack {
            Spacer().frame(width: 20)
            TextField("Min", value: $rangemin, formatter: TwoDigitNumber)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(modifier == .positive)
                .onChange(of: modifier) { value in
                    switch value {
                        case .positive: rangemin = 0.0
                        case .symmetric: rangemin = -min(abs(rangemin), abs(rangemax))
                        default: break
                    }
                }
            Slider(value: $rangemin, in: datamin...datamax) {}.frame(width: 160)
                .disabled(modifier == .positive)
            Spacer()
            Picker("Range:", selection: $modifier) {
                ForEach(BoundsModifier.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .frame(width: 150)
            Spacer()
            Slider(value: $rangemax, in: datamin...datamax) {}.frame(width: 160)
                .disabled(modifier == .negative)
            TextField("Max", value: $rangemax, formatter: TwoDigitNumber)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(modifier == .negative)
                .onChange(of: modifier) { value in
                    switch value {
                        case .negative: rangemax = 0.0
                        case .symmetric: rangemax = min(abs(rangemin), abs(rangemax))
                        default: break
                    }
                }
            Spacer().frame(width: 20)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
   }
}
