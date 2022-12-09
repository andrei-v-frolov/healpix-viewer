//
//  StatView.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-12-02.
//

import SwiftUI
import Charts

// CDF and PDF data point for charts
struct Distribution: Identifiable {
    var id: Double { return x }
    
    let x: Double
    let cdf: Double
    let pdf: Double
    let delta: Double
}

// summary statistics for charts
struct Statistics {
    // moments
    let mean: Double
    let sigma: Double
    let skewness: Double
    let kurtosis: Double
    
    // L-moments
    let median: Double
    let scale: Double
    let tau3: Double
    let tau4: Double
}

@available(macOS 13.0, *)
struct StatView: View {
    @Binding var overlay: ShowOverlay
    @Binding var cdf: [Double]?
    
    @Binding var rangemin: Double
    @Binding var rangemax: Double
    
    // summary statistics from CDF compendium
    var stat: Statistics {
        guard let cdf = cdf, cdf.count > 8 else { return Statistics(mean: 0.0, sigma: 0.0, skewness: 0.0, kurtosis: 0.0, median: 0.0, scale: 0.0, tau3: 0.0, tau4: 0.0) }
        let n = cdf.count, u = [0.0, 55.0/24.0, -4.0/24.0, 33.0/24.0, 1.0].map { $0/Double(n-1) }
        
        // initialize accumulators
        var mu1 = 0.0, mu2 = 0.0, mu3 = 0.0, mu4 = 0.0
        var lambda2 = 0.0, lambda3 = 0.0, lambda4 = 0.0
        
        // open-ended quadrature, NR 4.1.18
        for i in 0..<n {
            let x = cdf[i], F = Double(i)/Double(n-1), w = u[min(i,n-i-1,4)]
            
            mu1 += w*x; mu2 += w*x*x; mu3 += w*x*x*x; mu4 += w*x*x*x*x
            lambda2 += w * (2.0*F-1.0) * x
            lambda3 += w * (6.0*(F-1.0)*F + 1.0) * x
            lambda4 += w * ((20.0*(F-1.5)*F + 12.0)*F - 1.0) * x
        }
        
        // standard deviation
        let sigma = sqrt(mu2 - mu1*mu1)
        
        return Statistics(mean: mu1, sigma: sigma,
                          skewness: (mu3 - 3*mu2*mu1 + 2*mu1*mu1*mu1)/pow(sigma,3),
                          kurtosis: (mu4 - 4*mu3*mu1 + 6*mu2*mu1*mu1 - 3*mu1*mu1*mu1*mu1)/pow(sigma,4),
                          median: percentile(0.50), scale: lambda2, tau3: lambda3/lambda2, tau4: lambda4/lambda2)
    }
    
    // number format for summary statistics
    private let format = "%+.8g"
    
    // summary chart data from CDF compendium
    var data: [Distribution] {
        guard let cdf = cdf, cdf.count > 2 else { return [Distribution]() }
        let n = cdf.count; var dist = [Distribution](); dist.reserveCapacity(n)
        var delta = 0.0, k = -1, regular = [Double](); regular.reserveCapacity(n)
        
        // extract delta-like contributions to CDF
        for i in 0..<n {
            if (i < n-1 && cdf[i+1] == cdf[i]) {
                if (regular.count > 0) { dist += decimate(regular, from: n, by: 16, offset: k); regular.removeAll(); k = -1 }
                delta += 1.0/Double(n-1)
            } else if (delta > 0.0) {
                dist.append(dbar(x: cdf[i], delta: delta)); delta = 0.0
            } else {
                if (k < 0) { k = i }
                regular.append(cdf[i])
            }
        }
        
        // finalize regular contribution
        if (regular.count > 0) { dist += decimate(regular, from: n, by: 16, offset: k) }
        
        // renormalize PDF to unit max value
        let maxpdf = dist.map { $0.pdf }.max() ?? 0.0
        
        return (maxpdf > 0.0) ? dist.map { rescale($0, maxpdf: maxpdf) } : dist
    }
    
    // chart view body
    var body: some View {
        VStack(spacing: 0) {
            Chart(data) {
                if ($0.cdf >= 0.0) {
                    LineMark(
                        x: .value("Value", $0.x),
                        y: .value("CDF", $0.cdf)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(.init(lineWidth: 5))
                    .foregroundStyle(Gradient(colors: [.red, .white, .blue]))
                }
                if ($0.pdf >= 0.0) {
                    AreaMark(
                        x: .value("Value", $0.x),
                        y: .value("PDF", $0.pdf)
                    )
                    .foregroundStyle(Gradient(colors: [.primary.opacity(0.5), .secondary.opacity(0.5)]))
                }
                if ($0.delta > 0.0) {
                    BarMark(
                        x: .value("Value", $0.x),
                        y: .value("delta", $0.delta)
                    )
                    .foregroundStyle(Color(.red))
                }
            }
            .chartXScale(domain: rangemin...rangemax)
            .padding([.leading,.trailing,.top], 30)
            HStack {
                Spacer()
                VStack {
                    Text("Moments").font(.headline)
                    HStack {
                        VStack(alignment: .trailing) {
                            Text("Mean μ:")
                            Text("Stddev σ:")
                            Text("Skewness:")
                            Text("Kurtosis:")
                        }
                        VStack(alignment: .leading) {
                            Text(String(format: format, stat.mean))
                            Text(String(format: format, stat.sigma))
                            Text(String(format: format, stat.skewness))
                            Text(String(format: format, stat.kurtosis))
                        }
                    }
                }
                Spacer()
                VStack {
                    Text("L-Moments").font(.headline)
                    HStack {
                        VStack(alignment: .trailing) {
                            Text("Median:")
                            Text("L-scale:")
                            Text("L-skewness:")
                            Text("L-kurtosis:")
                        }
                        VStack(alignment: .leading) {
                            Text(String(format: format, stat.median))
                            Text(String(format: format, stat.scale))
                            Text(String(format: format, stat.tau3))
                            Text(String(format: format, stat.tau4))
                        }
                    }
                }
                Spacer()
                VStack {
                    Text("Percentiles").font(.headline)
                    HStack {
                        VStack(alignment: .trailing) {
                            Text("2.3%:")
                            Text("15.9%:")
                            Text("84.1%:")
                            Text("97.7%:")
                        }
                        VStack(alignment: .leading) {
                            Text(String(format: format, percentile(0.0227501320)))
                            Text(String(format: format, percentile(0.1586552540)))
                            Text(String(format: format, percentile(0.8413447460)))
                            Text(String(format: format, percentile(0.9772498680)))
                        }
                    }
                }
                Spacer()
            }
            .font(Font.system(size: 13).monospaced())
            .padding(10)
            HStack {
                Button("Set range to μ±5σ") {
                    let stat = stat
                    rangemin = stat.mean - 5*stat.sigma
                    rangemax = stat.mean + 5*stat.sigma
                    withAnimation { overlay = .none }
                }
                Button("Set range to μ±3σ") {
                    let stat = stat
                    rangemin = stat.mean - 3*stat.sigma
                    rangemax = stat.mean + 3*stat.sigma
                    withAnimation { overlay = .none }
                }
                Button("Set range to 99.73%") {
                    rangemin = percentile(0.0013498980)
                    rangemax = percentile(0.9986501020)
                    withAnimation { overlay = .none }
                }
                Button("Set range to 99.99%") {
                    rangemin = percentile(0.00005)
                    rangemax = percentile(0.99995)
                    withAnimation { overlay = .none }
                }
            }
            .padding(10)
        }
    }
    
    // linear interpolation of percentile value
    func percentile(_ x: Double) -> Double {
        guard let cdf = cdf, cdf.count > 1 else { return 0.0 }
        
        let n = cdf.count, k = min(Int(floor(x*Double(n-1))), n-2)
        let a = Double(k)/Double(n-1), b = Double(k+1)/Double(n-1)
        
        return ((b-x)*cdf[k] + (x-a)*cdf[k+1])/(b-a)
    }
    
    // decimate a regulat chunk of CDF data
    func decimate(_ cdf: [Double], from samples: Int, by k: Int, offset: Int = 0) -> [Distribution] {
        let n = cdf.count; var dist = [Distribution](); dist.reserveCapacity(n/k + 1)
        
        if (n > 0) { dist.append(Distribution(x: cdf[0], cdf: Double(offset)/Double(samples-1), pdf: (offset == 0 ? 0.0 : -1.0), delta: 0.0)) }
        
        for i in stride(from: (n/2) % k, to: n, by: k) {
            if (i-k >= 0 && i+k < n) {
                let x = cdf[i]
                let F = Double(i+offset)/Double(samples-1)
                let P = 2.0/(cdf[i+k]-cdf[i-k])
                
                dist.append(Distribution(x: x, cdf: F, pdf: P, delta: 0.0))
            }
        }
        
        if (n > 1) { dist.append(Distribution(x: cdf[n-1], cdf: Double(n-1+offset)/Double(samples-1), pdf: (n+offset == samples ? 0.0 : -1.0), delta: 0.0)) }
        
        return dist
    }
    
    // rescale PDF data
    func rescale(_ p: Distribution, maxpdf: Double) -> Distribution {
        return p.pdf > 0.0 ? Distribution(x: p.x, cdf: p.cdf, pdf: p.pdf/maxpdf, delta: p.delta) : p
    }
    
    // delta-like contribution to CDF is represented as a bar
    func dbar(x: Double, delta: Double) -> Distribution {
        return Distribution(x: x, cdf: -1.0, pdf: -1.0, delta: delta)
    }
}
