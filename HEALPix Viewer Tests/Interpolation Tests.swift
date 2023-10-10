//
//  Interpolation Tests.swift
//  HEALPix Viewer Tests
//
//  Created by Andrei Frolov on 2023-10-03.
//

import XCTest

final class Interpolation_Tests: XCTestCase {
    let tries = 8, pts = 64
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_linear_4() throws {
        let epsilon = 1.5/(pow(Double(pts),2)), n = 8*pts
        
        for _ in 0..<tries {
            let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1), x4 = Double.random(in: 0...1)
            
            let x = Array(0..<pts).map { Double($0)/Double(pts-1) }
            let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)*(x-x4), (x-x1)*(x-x2)*(x-x3), (x-x1)*(x-x2), (x-x1)) }
            let spline = CubicSpline(x: x, y: y), lut = spline.linear(lut: n)
            
            for i in 0..<n {
                let x = Double(i)/Double(n-1)
                XCTAssertEqual(spline.linear(x)[0], (x-x1)*(x-x2)*(x-x3)*(x-x4), accuracy: epsilon)
                XCTAssertEqual(spline.linear(x)[1], (x-x1)*(x-x2)*(x-x3), accuracy: epsilon)
                XCTAssertEqual(spline.linear(x)[2], (x-x1)*(x-x2), accuracy: epsilon)
                XCTAssertEqual(spline.linear(x)[3], (x-x1), accuracy: epsilon)
                XCTAssertEqual(lut[i], spline.linear(x))
            }
        }
    }
    
    func test_spline_4() throws {
        let epsilon = 0.5/(pow(Double(pts),2)), n = 8*pts
        
        for _ in 0..<tries {
            let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1), x4 = Double.random(in: 0...1)
            
            let x = Array(0..<pts).map { Double($0)/Double(pts-1) }
            let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)*(x-x4), (x-x1)*(x-x2)*(x-x3), (x-x1)*(x-x2), (x-x1)) }
            let spline = CubicSpline(x: x, y: y), lut = spline.cubic(lut: n)
            
            for i in 0..<n {
                let x = Double(i)/Double(n-1)
                XCTAssertEqual(spline[x][0], (x-x1)*(x-x2)*(x-x3)*(x-x4), accuracy: epsilon)
                XCTAssertEqual(spline[x][1], (x-x1)*(x-x2)*(x-x3), accuracy: epsilon)
                XCTAssertEqual(spline[x][2], (x-x1)*(x-x2), accuracy: epsilon)
                XCTAssertEqual(spline[x][3], (x-x1), accuracy: epsilon)
                XCTAssertEqual(lut[i], spline[x])
            }
        }
    }
    
    func test_init_double4() throws {
        let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1), x4 = Double.random(in: 0...1)
        
        let pts = 2<<13, x = Array(0..<pts).map { Double($0)/Double(pts-1) }
        let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)*(x-x4), (x-x1)*(x-x2)*(x-x3), (x-x1)*(x-x2), (x-x1)) }
        self.measure { let spline = CubicSpline(x: x, y: y) }
    }
    
    func test_lut_double4() throws {
        let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1), x4 = Double.random(in: 0...1)
        
        let pts = 16, x = Array(0..<pts).map { Double($0)/Double(pts-1) }
        let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)*(x-x4), (x-x1)*(x-x2)*(x-x3), (x-x1)*(x-x2), (x-x1)) }
        self.measure { let spline = CubicSpline(x: x, y: y); let _ = spline.cubic(lut: 2<<15) }
    }
    
    func test_lookup_double4() throws {
        let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1), x4 = Double.random(in: 0...1)
        
        let pts = 16, x = Array(0..<pts).map { Double($0)/Double(pts-1) }
        let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)*(x-x4), (x-x1)*(x-x2)*(x-x3), (x-x1)*(x-x2), (x-x1)) }
        self.measure { let spline = CubicSpline(x: x, y: y); for _ in 0..<2<<15 { let _ = spline[Double.random(in: 0...1)] } }
    }
}
