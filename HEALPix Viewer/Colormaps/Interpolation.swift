//
//  Interpolation.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-10-03.
//

import Foundation
import simd

// cubic spline interpolator [heavily optimized from https://github.com/gscalzo/SwiftCubicSpline]
struct CubicSpline<Value> where Value: SIMD, Value.Scalar: FloatingPoint {
    private var x: [Value.Scalar]
    private var a: [Value]
    private var b: [Value]
    private var c: [Value]
    private var d: [Value]
    
    // bisection search (only useful for large arrays)
    func find(_ value: Value.Scalar) -> Int {
        guard x.count > 16 else { return x.lastIndex(where: { $0 <= value }) ?? x.startIndex }
        guard let u = x.first, value > u else { return x.startIndex }
        guard let u = x.last,  value < u else { return x.endIndex-1 }
        
        var low = x.startIndex, high = x.endIndex-1
        while low+1 < high { let mid = (low+high)/2; if value < x[mid] { high = mid } else { low = mid} }
        
        return low
    }
    
    // linear interpolated value
    func linear(_ value: Value.Scalar) -> Value {
        let i = min(find(value),max(x.startIndex,x.endIndex-2))
        let q = (value - x[i])/(x[i+1] - x[i])
        return (1-q)*a[i] + q*a[i+1]
    }
    
    // linear interpolated LUT
    func linear(lut n: Int) -> [Value] {
        var y = [Value](repeating: .zero, count: n), k = x.startIndex
        
        for i in 0..<n {
            let value = Value.Scalar(i)/Value.Scalar(n-1)
            while k < x.endIndex-2, x[k+1] <= value { k += 1 }
            let q = (value - x[k])/(x[k+1] - x[k]); y[i] = (1-q)*a[k] + q*a[k+1]
        }
        
        return y
    }
    
    // cubic interpolated value
    func cubic(_ value: Value.Scalar) -> Value {
        let i = find(value), dx = value - x[i]
        return a[i] + dx*(b[i] + dx*(c[i] + dx*d[i]))
    }
    
    // cubic interpolated LUT
    func cubic(lut n: Int) -> [Value] {
        var y = [Value](repeating: .zero, count: n), k = x.startIndex
        
        for i in 0..<n {
            let value = Value.Scalar(i)/Value.Scalar(n-1)
            while k < x.endIndex-1, x[k+1] <= value { k += 1 }
            let dx = value - x[k]; y[i] = a[k] + dx*(b[k] + dx*(c[k] + dx*d[k]))
        }
        
        return y
    }
    
    // lookup interpolated value
    subscript(_ value: Value.Scalar) -> Value { cubic(value) }
    
    // initialize spline LUT
    init(x: [Value.Scalar], y: [Value]) {
        let n = x.count; assert(y.count == n, "Input dimensions mismatch in CubicSpline")
        
        self.x = x
        self.a = y
        self.b = [Value](repeating: .zero, count: n)
        self.c = [Value](repeating: .zero, count: n)
        self.d = [Value](repeating: .zero, count: n)
        
        guard (n > 0) else { return }
        
        var u = [Value](repeating: .zero, count: n)
        var z = [Value](repeating: .zero, count: n)
        
        for i in 1..<n-1 {
            let p = 2 * (x[i+1] - x[i-1]) - (x[i] - x[i-1]) * u[i-1]
            let q = (a[i+1] - a[i])/(x[i+1] - x[i]) - (a[i] - a[i-1])/(x[i] - x[i-1])
            u[i] = (x[i+1] - x[i])/p; z[i] = (3*q - (x[i] - x[i-1]) * z[i-1])/p
        }
        
        for i in stride(from: n-2, through: 0, by: -1) {
            let h = x[i+1] - x[i]
            c[i] = z[i] - u[i] * c[i+1]
            b[i] = (a[i+1] - a[i])/h - (h/3) * (c[i+1] + 2*c[i])
            d[i] = (c[i+1] - c[i])/(3*h)
        }
    }
}
