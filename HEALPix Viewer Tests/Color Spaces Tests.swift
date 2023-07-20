//
//  ColorSpaces Tests.swift
//  HEALPix ViewerTests
//
//  Created by Andrei Frolov on 2023-07-18.
//

import XCTest

final class ColorSpaces_Tests: XCTestCase {
    let pts = 1024, epsilon = 1.0e-12
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_srgb() throws {
        XCTAssertEqual(lin2srgb(0.0), 0.0, accuracy: epsilon)
        XCTAssertEqual(lin2srgb(1.0), 1.0, accuracy: epsilon)
        
        for i in 0..<pts {
            let x = Double(i)/Double(pts-1), y = srgb2lin(x), z = lin2srgb(y)
            XCTAssertEqual(x, z, accuracy: epsilon)
        }
    }
    
    func test_hlg() throws {
        XCTAssertEqual(lin2hlg(0.0), 0.0, accuracy: epsilon)
        XCTAssertEqual(lin2hlg(1.0), 1.0, accuracy: epsilon)
        
        for i in 0..<pts {
            let x = Double(i)/Double(pts-1), y = hlg2lin(x), z = lin2hlg(y)
            XCTAssertEqual(x, z, accuracy: epsilon)
        }
    }
    
    func test_okLab() throws {
        for _ in 0..<64*pts {
            let x = SIMD3<Double>(Double.random(in: 0...1),Double.random(in: 0...1),Double.random(in: 0...1))
            
            let v = lrgb2ok(x), w = ok2lrgb(v)
            XCTAssertEqual(x[0], w[0], accuracy: epsilon)
            XCTAssertEqual(x[1], w[1], accuracy: epsilon)
            XCTAssertEqual(x[2], w[2], accuracy: epsilon)
            
            let y = srgb2ok(x), z = ok2srgb(y)
            XCTAssertEqual(x[0], z[0], accuracy: epsilon)
            XCTAssertEqual(x[1], z[1], accuracy: epsilon)
            XCTAssertEqual(x[2], z[2], accuracy: epsilon)
        }

    }
}
