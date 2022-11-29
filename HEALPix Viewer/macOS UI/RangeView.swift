//
//  RangeView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-08.
//

import SwiftUI

struct RangeToolbar: View, Equatable {
    @Binding var map: (any Map)?
    @Binding var modifier: BoundsModifier
    
    @Binding var datamin: Double
    @Binding var datamax: Double
    
    @Binding var rangemin: Double
    @Binding var rangemax: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Spacer().frame(width: 20)
            TextField("Min", value: $rangemin, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(modifier == .positive)
                .focused($focus)
                .onChange(of: modifier) { value in
                    switch value {
                        case .positive: rangemin = 0.0
                        case .symmetric: rangemin = -max(abs(rangemin), abs(rangemax))
                        case .full: if let map = map { datamin = map.min; rangemin = datamin }
                        default: break
                    }
                }
                .onChange(of: rangemin) { value in
                    if ((modifier == .negative || modifier == .symmetric) && value > 0.0) { rangemin = 0.0 }
                    if (modifier == .symmetric) { rangemax = -value }
                    if (rangemin > rangemax) { rangemax = rangemin }
                }
            Slider(value: $rangemin, in: datamin...(modifier == .symmetric || modifier == .negative ? 0.0 : datamax)) {} onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(modifier == .positive)
            Spacer()
            Picker("Range:", selection: $modifier) {
                Text(BoundsModifier.full.rawValue).tag(BoundsModifier.full)
                Text(BoundsModifier.symmetric.rawValue).tag(BoundsModifier.symmetric)
                if (datamax > 0.0) { Text(BoundsModifier.positive.rawValue).tag(BoundsModifier.positive) }
                if (datamin < 0.0) { Text(BoundsModifier.negative.rawValue).tag(BoundsModifier.negative) }
            }
            .frame(width: 150)
            Spacer()
            Slider(value: $rangemax, in: (modifier == .symmetric || modifier == .positive ? 0.0 : datamin)...datamax) {} onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(modifier == .negative)
            TextField("Max", value: $rangemax, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(modifier == .negative)
                .focused($focus)
                .onChange(of: modifier) { value in
                    switch value {
                        case .negative: rangemax = 0.0
                        case .symmetric: rangemax = max(abs(rangemin), abs(rangemax))
                        case .full: if let map = map { datamax = map.max; rangemax = datamax }
                        default: break
                    }
                }
                .onChange(of: rangemax) { value in
                    if ((modifier == .positive || modifier == .symmetric) && value < 0.0) { rangemax = 0.0 }
                    if (modifier == .symmetric) { rangemin = -value }
                    if (rangemin > rangemax) { rangemin = rangemax }
                }
            Spacer().frame(width: 20)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
    }
    
    // comparing view state
    static func == (a: Self, b: Self) -> Bool {
        return a.modifier == b.modifier &&
               a.datamin == b.datamin && a.rangemin == b.rangemin &&
               a.datamax == b.datamin && a.rangemax == b.rangemax
    }
}
