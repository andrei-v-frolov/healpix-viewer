//
//  Extensions.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-17.
//

import Foundation
import Accelerate
import MetalKit

// erfinv from Mike Giles, single precision
func erfinv(_ x: Double) -> Double {
    var w = -log((1.0-x)*(1.0+x)), p = 0.0
    
    if (w < 5.0) {
        w = w - 2.5
        p =  2.81022636e-08
        p =  3.43273939e-07 + p*w
        p = -3.52338770e-06 + p*w
        p = -4.39150654e-06 + p*w
        p =   0.00021858087 + p*w
        p =  -0.00125372503 + p*w
        p =  -0.00417768164 + p*w
        p =     0.246640727 + p*w
        p =      1.50140941 + p*w
    } else {
        w = sqrt(w) - 3.0
        p = -0.000200214257
        p =  0.000100950558 + p*w
        p =   0.00134934322 + p*w
        p =  -0.00367342844 + p*w
        p =   0.00573950773 + p*w
        p =  -0.00762246130 + p*w
        p =   0.00943887047 + p*w
        p =      1.00167406 + p*w
        p =      2.83297682 + p*w
    }
    
    return p*x
}

// singular value decomposition for float3x3 matrices
extension float3x3 {
    var svd: (s: float3, u: float3x3, v: float3x3)? {
        var a = self, s = float3(0), u = float3x3(0.0), v = float3x3(0.0)
        
        // memory layout
        let p = MemoryLayout<float3>.size/MemoryLayout<Float>.size
        let q = MemoryLayout<float3x3>.size/MemoryLayout<Float>.size
        
        // pointers to SIMD arrays
        let ap = UnsafeMutableRawPointer(&a).bindMemory(to: Float.self, capacity: q)
        let sp = UnsafeMutableRawPointer(&s).bindMemory(to: Float.self, capacity: p)
        let up = UnsafeMutableRawPointer(&u).bindMemory(to: Float.self, capacity: q)
        let vp = UnsafeMutableRawPointer(&v).bindMemory(to: Float.self, capacity: q)
        
        // LAPACK sgesvd parameters
        var jobu = Character("A").asciiValue!, jobv = jobu
        var m = __CLPK_integer(3), n = m, lda = __CLPK_integer(p), ldu = lda, ldv = lda
        var lwork = __CLPK_integer(32), info = __CLPK_integer(0)
        var work = [Float](repeating: 0, count: Int(lwork))
        
        // call LAPACK and check status
        sgesvd_(&jobu, &jobv, &m, &n, ap, &lda, sp, up, &ldu, vp, &ldv, &work, &lwork, &info)
        guard (info == 0) else { return nil }
        
        return (s, u, v)
    }
}
