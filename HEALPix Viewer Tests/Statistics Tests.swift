//
//  Statistics Tests.swift
//  HEALPix Viewer Tests
//
//  Created by Andrei Frolov on 2024-08-24.
//

import XCTest
import simd

final class Statistics_Tests: XCTestCase {
    let pts = 1024, epsilon = 1.0e-7, delta = 3.0e-4
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_cdf() throws {
        for d in Distribution.allCases {
            let cdf = CDF(d, count: pts<<2)
            for i in 0..<pts {
                let F = (Double(i)+0.5)/Double(pts), x = d.x(F), z = d.F(x)
                let P = d.P(x), y = (d.F(x+epsilon) - d.F(x-epsilon))/(2.0*epsilon)
                XCTAssertEqual(z, F, accuracy: epsilon)
                XCTAssertEqual(y, P, accuracy: epsilon)
                XCTAssertEqual(cdf[F], x, accuracy: delta)
            }
        }
    }
    
    func test_lookup() throws {
        for d in Distribution.allCases {
            let cdf = CDF(d, count: pts<<2)
            for i in 0..<cdf.n {
                let F = cdf.F[i], x = cdf.x[i]
                XCTAssertEqual(cdf[F], x, accuracy: epsilon)
            }
        }
    }
    
    func test_moments() throws {
        for d in Distribution.allCases {
            let cdf = CDF(d, count: pts<<2), epsilon = 1.0/Double(pts)
            XCTAssertEqual(distance(cdf.moments, d.moments), 0.0, accuracy: epsilon)
            XCTAssertEqual(distance(cdf.lmoments, d.lmoments), 0.0, accuracy: epsilon)
        }
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
