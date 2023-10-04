//
//  Interpolation.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-10-03.
//

import Foundation
import simd

// cubic spline interpolator [adopted from https://github.com/gscalzo/SwiftCubicSpline]
struct CubicSpline<Value> where Value: SIMD, Value.Scalar: FloatingPoint {
    private var x: [Value.Scalar]
    private var a: [Value]
    private var b: [Value]
    private var c: [Value]
    private var d: [Value]
    
    // lookup interpolated value
    subscript(_ value: Value.Scalar) -> Value {
        let i = x.lastIndex(where: { $0 <= value }) ?? x.startIndex, dx = value - x[i]
        return a[i] + dx*(b[i] + dx*(c[i] + dx*d[i]))
    }
    
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
