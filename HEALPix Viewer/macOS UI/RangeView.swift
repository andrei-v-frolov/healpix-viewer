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
    
    // lower bound slider range
    func lower(_ a: Double, _ b: Double) -> ClosedRange<Double> {
        switch range.mode {
            case .symmetric: return -max(abs(a),abs(b))...0.0
            case .negative: return min(a,b)...0.0
            default: return min(a,b)...max(a,b)
        }
    }
    
    // upper bound slider range
    func upper(_ a: Double, _ b: Double) -> ClosedRange<Double> {
        switch range.mode {
            case .symmetric: return 0.0...max(abs(a),abs(b))
            case .positive: return 0.0...max(a,b)
            default: return min(a,b)...max(a,b)
        }
    }
    
    var body: some View {
        HStack {
            Spacer().frame(width: 20)
            TextField("Min", value: $range.min, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(range.mode == .positive).focused($focus)
                .onChange(of: range.min) { value in
                    if ((range.mode == .negative || range.mode == .symmetric) && value > 0.0) { range.min = 0.0 }
                    if (range.mode == .symmetric) { range.max = -value }
                    if (range.min > range.max) { range.max = range.min }
                }
            Slider(value: $range.min, in: lower(datamin,datamax)) {} onEditingChanged: { editing in focus = false }
                .frame(width: 160).disabled(range.mode == .positive)
            Spacer()
            Picker("Range:", selection: $range.mode) {
                Text(BoundsModifier.full.rawValue).tag(BoundsModifier.full)
                Text(BoundsModifier.symmetric.rawValue).tag(BoundsModifier.symmetric)
                if (datamax > 0.0) { Text(BoundsModifier.positive.rawValue).tag(BoundsModifier.positive) }
                if (datamin < 0.0) { Text(BoundsModifier.negative.rawValue).tag(BoundsModifier.negative) }
            }
            .frame(width: 150)
            .onChange(of: range.mode) { value in
                focus = false
                switch value {
                    case .full:
                        range.min = datamin; range.max = datamax
                    case .symmetric:
                        let a = max(abs(range.min), abs(range.max))
                        range.min = -a; range.max = a
                    case .positive: range.min = 0.0
                    case .negative: range.max = 0.0
                }
            }
            Spacer()
            Slider(value: $range.max, in: upper(datamin,datamax)) {} onEditingChanged: { editing in focus = false }
                .frame(width: 160).disabled(range.mode == .negative)
            TextField("Max", value: $range.max, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(range.mode == .negative).focused($focus)
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
