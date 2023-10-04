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
    
    func test_spline_3() throws {
        let epsilon = 0.5/(pow(Double(pts),2))
        
        for _ in 0..<tries {
            let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1)
            
            let x = Array(0..<pts).map { Double($0)/Double(pts-1) }
            let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)) }
            let spline = CubicSpline(x: x, y: y)
            
            for i in 0..<8*pts {
                let x = Double(i)/Double(8*pts-1)
                XCTAssertEqual(spline[x][0], (x-x1)*(x-x2)*(x-x3), accuracy: epsilon)
            }
        }
    }
    
    func test_spline_4() throws {
        let epsilon = 0.5/(pow(Double(pts),2))
        
        for _ in 0..<tries {
            let x1 = Double.random(in: 0...1), x2 = Double.random(in: 0...1), x3 = Double.random(in: 0...1), x4 = Double.random(in: 0...1)
            
            let x = Array(0..<pts).map { Double($0)/Double(pts-1) }
            let y = x.map { x in SIMD4<Double>((x-x1)*(x-x2)*(x-x3)*(x-x4)) }
            let spline = CubicSpline(x: x, y: y)
            
            for i in 0..<8*pts {
                let x = Double(i)/Double(8*pts-1)
                XCTAssertEqual(spline[x][0], (x-x1)*(x-x2)*(x-x3)*(x-x4), accuracy: epsilon)
            }
        }
    }
}
