//
//  RangeView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-08.
//

import SwiftUI

struct RangeToolbar: View {
    @Binding var range: Bounds
    @Binding var datamin: Double
    @Binding var datamax: Double
    
    @FocusState private var focus: Bool
    
    var body: some View {
        HStack {
            Spacer().frame(width: 20)
            TextField("Min", value: $range.min, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(range.mode == .positive)
                .focused($focus)
                .onChange(of: range.mode) { value in
                    switch value {
                        case .positive: range.min = 0.0
                        case .symmetric: range.min = -max(abs(range.min), abs(range.max))
                        case .full: range.min = datamin
                        default: break
                    }
                }
                .onChange(of: range.min) { value in
                    if ((range.mode == .negative || range.mode == .symmetric) && value > 0.0) { range.min = 0.0 }
                    if (range.mode == .symmetric) { range.max = -value }
                    if (range.min > range.max) { range.max = range.min }
                }
            Slider(value: $range.min, in: datamin...(range.mode == .symmetric || range.mode == .negative ? 0.0 : datamax)) {} onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(range.mode == .positive)
            Spacer()
            Picker("Range:", selection: $range.mode) {
                Text(BoundsModifier.full.rawValue).tag(BoundsModifier.full)
                Text(BoundsModifier.symmetric.rawValue).tag(BoundsModifier.symmetric)
                if (datamax > 0.0) { Text(BoundsModifier.positive.rawValue).tag(BoundsModifier.positive) }
                if (datamin < 0.0) { Text(BoundsModifier.negative.rawValue).tag(BoundsModifier.negative) }
            }
            .frame(width: 150)
            Spacer()
            Slider(value: $range.max, in: (range.mode == .symmetric || range.mode == .positive ? 0.0 : datamin)...datamax) {} onEditingChanged: { editing in focus = false }
                .frame(width: 160)
                .disabled(range.mode == .negative)
            TextField("Max", value: $range.max, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(range.mode == .negative)
                .focused($focus)
                .onChange(of: range.mode) { value in
                    switch value {
                        case .negative: range.max = 0.0
                        case .symmetric: range.max = max(abs(range.min), abs(range.max))
                        case .full: range.max = datamax
                        default: break
                    }
                }
                .onChange(of: range.max) { value in
                    if ((range.mode == .positive || range.mode == .symmetric) && value < 0.0) { range.max = 0.0 }
                    if (range.mode == .symmetric) { range.min = -value }
                    if (range.min > range.max) { range.min = range.max }
                }
            Spacer().frame(width: 20)
        }
        .padding(.top, 11)
        .padding(.bottom, 10)
    }
}
