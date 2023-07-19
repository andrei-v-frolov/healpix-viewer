//
//  ColorSpaces Tests.swift
//  HEALPix ViewerTests
//
//  Created by Andrei Frolov on 2023-07-18.
//

import XCTest

final class ColorSpaces_Tests: XCTestCase {
    let pts = 1024
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_srgb() throws {
        for i in 0..<pts {
            let x = Double(i)/Double(pts-1), y = srgb2lin(x), z = lin2srgb(y)
            XCTAssertEqual(x, z, accuracy: 1.0e-12)
        }
    }
    
    func test_hlg() throws {
        for i in 0..<pts {
            let x = Double(i)/Double(pts-1), y = hlg2lin(x), z = lin2hlg(y)
            XCTAssertEqual(x, z, accuracy: 1.0e-12)
        }
    }
}
