//
//  Stats.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2024-08-22.
//

import Foundation

// common probability distributions
enum Distribution: CaseIterable {
    case normal(mu: Double, sigma: Double)
    case gumbel(mu: Double, beta: Double)
    // laplace
    // logistic
    // uniform?
    // delta?
    
    // canonical cases
    static var allCases: [Distribution] = [
        .normal(mu: 0.0, sigma: 1.0),
        .gumbel(mu: 1.0, beta: 2.0),
        .gumbel(mu: 6.0, beta: 4.0)
    ]
    
    // distribution PDF
    func P(_ x: Double) -> Double {
        switch self {
            case .normal(let mu, let sigma):
                let nu = (x-mu)/sigma; return exp(-nu*nu/2.0)/(sqrt2pi*sigma)
            case .gumbel(let mu, let beta):
                let nu = (x-mu)/beta; return exp(-nu-exp(-nu))/beta
        }
    }
    
    // distribution CDF
    func F(_ x: Double) -> Double {
        switch self {
            case .normal(let mu, let sigma):
                let nu = (x-mu)/sigma; return (1.0 + erf(nu/sqrt2))/2.0
            case .gumbel(let mu, let beta):
                let nu = (x-mu)/beta; return exp(-exp(-nu))
        }
    }
    
    // inverse CDF
    func x(_ F: Double) -> Double {
        switch self {
            case .normal(let mu, let sigma):
                let nu = sqrt2 * erfinv(2.0*F-1.0); return sigma*nu + mu
            case .gumbel(let mu, let beta):
                let nu = -log(-log(F)); return beta*nu + mu
        }
    }
    
    // distribution mean, sigma, skewness, and kurtosis
    var moments: SIMD4<Double> {
        switch self {
            case .normal(let mu, let sigma):
                return SIMD4<Double>(mu, sigma, 0.0, 3.0)
            case .gumbel(let mu, let beta):
                return SIMD4<Double>(mu + euler*beta, (Double.pi/sqrt6)*beta, 1.139547099404648657492793019389846112087599795837, 5.4)
        }
    }
    
    // distribution median, scale, L-skewness, and L-kurtosis
    var lmoments: SIMD4<Double> {
        switch self {
            case .normal(let mu, let sigma):
                return SIMD4<Double>(mu, sigma/sqrtpi, 0.0, 0.122601719540890947437166611663536330250570258409)
            case .gumbel(let mu, let beta):
                return SIMD4<Double>(mu - beta*log(ln2), beta*ln2, 2.0*ln3/ln2 - 3.0, 16.0 - 10.0*ln3/ln2)
        }
    }
    
    // distribution percentile brackets
    var brackets: SIMD4<Double> {
        SIMD4<Double>(
            x(0.022750131948179207200282637166533437471776223702),
            x(0.158655253931457051414767454367962077522087033273),
            x(0.841344746068542948585232545632037922477912966727),
            x(0.977249868051820792799717362833466562528223776298))
    }
    
    // draw a random sample array (NOT vectorized, hence slow)
    var sample: Double { x(Double.random(in: 0.0...1.0)) }
    func draw(count: Int) -> [Double] { return (0..<count).map { _ in sample } }
}

// light-weight CDF representation (sampled on Chebyshev grid)
struct CDF {
    let n: Int
    let F: [Double]
    let x: [Double]
    let w: [Double]
    
    // initialize from known distribution
    init(_ distribution: Distribution, count n: Int) {
        let dt = halfpi/Double(n)
        
        // sampling arrays
        var F = [Double](repeating: 0.0, count: n)
        var x = [Double](repeating: 0.0, count: n)
        var w = [Double](repeating: 0.0, count: n)
        
        // Chebyshev grid
        for i in 0..<n {
            let t = (Double(i)+0.5)*dt, z = sin(t)
            F[i] = z*z; x[i] = distribution.x(z*z)
            w[i] = sin(2.0*t)*dt
        }
        
        // initialize self
        self.n = n
        self.F = F
        self.x = x
        self.w = w
    }
    
    // initialize from indexed data
    init(_ data: UnsafePointer<Float>, index idx: UnsafeBufferPointer<Int32>, count n: Int) {
        let dt = halfpi/Double(n), nobs = idx.count
        
        // sampling arrays
        var F = [Double](repeating: 0.0, count: n)
        var x = [Double](repeating: 0.0, count: n)
        var w = [Double](repeating: 0.0, count: n)
        
        // Chebyshev grid
        for i in 0..<n {
            let t = (Double(i)+0.5)*dt, z = sin(t), r = Double(nobs)*z*z - 0.5
            let k = min(max(Int(floor(r)),0),nobs-2), alpha = r - Double(k)
            let a = Double(data[Int(idx[k])]), b = Double(data[Int(idx[k+1])])
            F[i] = z*z; x[i] = (1.0-alpha)*a + alpha*b; w[i] = sin(2.0*t)*dt
        }
        
        // initialize self
        self.n = n
        self.F = F
        self.x = x
        self.w = w
    }
    
    // convenience init from loaded map
    init(map: Map, count n: Int) { self.init(map.ptr, index: map.idx, count: n) }
    
    // distribution mean, sigma, skewness, and kurtosis
    var moments: SIMD4<Double> {
        var mu = SIMD4<Double>.zero
        
        // accumulate moments
        for i in 0..<n {
            let w = w[i], x = x[i], x2 = x*x
            mu += w * SIMD4<Double>(x, x2, x*x2, x2*x2)
        }
        
        // distribution parameters
        let mean = mu.x, mu2 = mu.x*mu.x, sigma = sqrt(mu.y - mu2)
        let skewness = (mu.z - (3*mu.y-2*mu2) * mean)/pow(sigma,3)
        let kurtosis = (mu.w - (4*mu.z - 3*(2*mu.y-mu2) * mean) * mean)/pow(sigma,4)
        
        return SIMD4<Double>(mu.x, sigma, skewness, kurtosis)
    }
    
    // distribution median, scale, L-skewness, and L-kurtosis
    var lmoments: SIMD4<Double> {
        var lambda = SIMD4<Double>.zero
        
        // accumulate L-moments
        for i in 0..<n {
            let w = w[i] * x[i], F = F[i]
            lambda += w * SIMD4<Double>(1.0, 2.0*F-1.0, 6.0*(F-1.0)*F + 1.0, (20.0*(F-1.5)*F + 12.0)*F - 1.0)
        }
        
        return SIMD4<Double>(self[0.5], lambda.y, lambda.z/lambda.y, lambda.w/lambda.y)
    }
    
    // distrubution percentile (using linear interpolation)
    subscript(_ F: Double) -> Double {
        let dt = halfpi/Double(n), t = asin(sqrt(F))/dt - 0.5
        let k = min(max(Int(floor(t)),0),n-2), alpha = t - Double(k)
        return (1.0-alpha)*x[k] + alpha*x[k+1]
    }
    
    // ... decimate ...
    
    // ... discontinuity finder ...
    // ... PDF estimator ...
}
