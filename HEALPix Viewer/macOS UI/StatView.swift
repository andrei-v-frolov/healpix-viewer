//
//  StatView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-12-02.
//

import SwiftUI
import Charts

// CDF and PDF data for charts
struct Distribution: Identifiable {
    let id: Int
    
    let x: Double
    let cdf: Double
    let pdf: Double
    let delta: Double
}

// fake distribution data for testing
let test: [Distribution] = {
    var data = [Distribution](); data.reserveCapacity(257)
    
    for i in 0..<256 {
        let x = Double(i)/256.0, twopi = 2.0*Double.pi
        let p = Distribution(id: i, x: 15.0*x-3.0, cdf: x-sin(twopi*x)/twopi, pdf: (1.0-cos(twopi*x))/2,
                             delta: (i == 73 ? 0.3 : 0.0) + (i == 137 ? 0.8 : 0.0))
        data.append(p)
    }
    
    return data
}()

@available(macOS 13.0, *)
struct StatView: View {
    var body: some View {
        VStack(spacing: 0) {
            Chart(test) {
                AreaMark(
                    x: .value("Value", $0.x),
                    y: .value("CDF", $0.cdf)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Gradient(colors: [.green.opacity(0.7), .mint.opacity(0.7), .cyan.opacity(0.7)]))
                LineMark(
                    x: .value("Value", $0.x),
                    y: .value("PDF", $0.pdf)
                )
                .lineStyle(.init(lineWidth: 5))
                if ($0.delta > 0.0) {
                    BarMark(
                        x: .value("Value", $0.x),
                        y: .value("delta", $0.delta)
                    )
                    .foregroundStyle(Color(.red))
                }
            }
            .chartXScale(domain: -3.1...12.1)
            .padding(30)
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Mean μ:")
                    Text("Stddev σ:")
                    Text("Skewness:")
                    Text("Kurtosis:")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Median:")
                    Text("L-scale:")
                    Text("L-skew:")
                    Text("L-kurtosis:")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("2% :")
                    Text("16% :")
                    Text("84% :")
                    Text("98% :")
                }
                Spacer()
            }
            .padding(10)
        }
    }
}
