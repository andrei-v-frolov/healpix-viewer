//
//  Extensions.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-17.
//

import Foundation
import Accelerate
import MetalKit

// global constants
let euler   = 0.577215664901532860606512090082402431042159335940    // Euler's constant
let ln2     = 0.693147180559945309417232121458176568075500134360    // log(2)
let ln3     = 1.098612288668109691395245236922525704647490557823    // log(3)
let sqrt2   = 1.414213562373095048801688724209698078569671875377    // sqrt(2)
let sqrt3   = 1.732050807568877293527446341505872366942805253810    // sqrt(3)
let sqrt6   = 2.449489742783178098197284074705891391965947480657    // sqrt(6)
let halfpi  = 1.570796326794896619231321691639751442098584699688    // pi/2
let sqrtpi  = 1.772453850905516027298167483341145182797549456122    // sqrt(pi)
let sqrt2pi = 2.506628274631000502415765284811045253006986740610    // sqrt(2*pi)

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

// convert precision of SIMD matrices
extension float4x4 { init(_ Q: double4x4) { self = float4x4(float4(Q[0]), float4(Q[1]), float4(Q[2]), float4(Q[3])) } }
extension float4x3 { init(_ Q: double4x3) { self = float4x3(float3(Q[0]), float3(Q[1]), float3(Q[2]), float3(Q[3])) } }
extension float3x4 { init(_ Q: double3x4) { self = float3x4(float4(Q[0]), float4(Q[1]), float4(Q[2])) } }
extension float3x3 { init(_ Q: double3x3) { self = float3x3(float3(Q[0]), float3(Q[1]), float3(Q[2])) } }

// singular value decomposition for float3x3 matrices
extension float3x3 {
    var svd: (s: float3, u: float3x3, v: float3x3)? {
        var a = self, s = float3(0), u = float3x3(0.0), v = float3x3(0.0)
        
        // memory layout
        let p = MemoryLayout<float3>.size/MemoryLayout<Float>.size
        let q = MemoryLayout<float3x3>.size/MemoryLayout<Float>.size
        
        // pointers to SIMD array data
        let ap = UnsafeMutableRawPointer(&a).bindMemory(to: Float.self, capacity: q)
        let sp = UnsafeMutableRawPointer(&s).bindMemory(to: Float.self, capacity: p)
        let up = UnsafeMutableRawPointer(&u).bindMemory(to: Float.self, capacity: q)
        let vp = UnsafeMutableRawPointer(&v).bindMemory(to: Float.self, capacity: q)
        
        // LAPACK sgesvd parameters
        var jobu = Character("A").asciiValue!, jobv = jobu
        var m = __CLPK_integer(3), n = m
        var lda = __CLPK_integer(p), ldu = lda, ldv = lda
        var lwork = __CLPK_integer(32), info = __CLPK_integer(0)
        var work = [Float](repeating: 0, count: Int(lwork))
        
        // call LAPACK and check status
        sgesvd_(&jobu, &jobv, &m, &n, ap, &lda, sp, up, &ldu, vp, &ldv, &work, &lwork, &info)
        guard (info == 0) else { return nil }
        
        return (s, u, v)
    }
}

// singular value decomposition for double3x3 matrices
extension double3x3 {
    var svd: (s: double3, u: double3x3, v: double3x3)? {
        var a = self, s = double3(0), u = double3x3(0.0), v = double3x3(0.0)
        
        // memory layout
        let p = MemoryLayout<double3>.size/MemoryLayout<Double>.size
        let q = MemoryLayout<double3x3>.size/MemoryLayout<Double>.size
        
        // pointers to SIMD array data
        let ap = UnsafeMutableRawPointer(&a).bindMemory(to: Double.self, capacity: q)
        let sp = UnsafeMutableRawPointer(&s).bindMemory(to: Double.self, capacity: p)
        let up = UnsafeMutableRawPointer(&u).bindMemory(to: Double.self, capacity: q)
        let vp = UnsafeMutableRawPointer(&v).bindMemory(to: Double.self, capacity: q)
        
        // LAPACK sgesvd parameters
        var jobu = Character("A").asciiValue!, jobv = jobu
        var m = __CLPK_integer(3), n = m
        var lda = __CLPK_integer(p), ldu = lda, ldv = lda
        var lwork = __CLPK_integer(32), info = __CLPK_integer(0)
        var work = [Double](repeating: 0, count: Int(lwork))
        
        // call LAPACK and check status
        dgesvd_(&jobu, &jobv, &m, &n, ap, &lda, sp, up, &ldu, vp, &ldv, &work, &lwork, &info)
        guard (info == 0) else { return nil }
        
        return (s, u, v)
    }
}

// shorthand for finding first identifiable occurance in array
extension Array where Element: Identifiable {
    subscript(id: Element.ID) -> Element? { self.first(where: { $0.id == id }) }
    subscript(id: Element.ID?) -> Element? { self.first(where: { $0.id == id }) }
}
