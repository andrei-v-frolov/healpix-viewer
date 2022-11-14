//
//  RangeView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-08.
//

import SwiftUI

// number formatter common to most fields
let SixDigitsScientific: NumberFormatter = {
    let format = NumberFormatter()
    
    format.numberStyle = .scientific
    format.usesSignificantDigits = true
    format.minimumSignificantDigits = 6
    format.maximumSignificantDigits = 6
    
    return format
}()

struct RangeView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct RangeToolbar: View, Equatable {
    @Binding var map: Map?
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
            Slider(value: $rangemin, in: datamin...datamax) {}.frame(width: 160)
                .disabled(modifier == .positive)
                .onChange(of: rangemin) { value in focus = false }
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
                .onChange(of: rangemax) { value in focus = false }
            TextField("Max", value: $rangemax, formatter: SixDigitsScientific)
                .frame(width: 95).multilineTextAlignment(.trailing)
                .disabled(modifier == .negative)
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
