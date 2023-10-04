//
//  HEALPix_Tests.swift
//  HEALPix ViewerTests
//
//  Created by Andrei Frolov on 2022-11-13.
//

import CFitsIO
import XCTest

final class HEALPix_Tests: XCTestCase {
    let maxtries = 123456
    let nsides = [16, 64, 256, 1024, 4096]
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_idx() throws {
        for nside in nsides {
            var skip = nside*nside/maxtries + 1, q = 0, r = 0
            
            for p in stride(from: 0, to: 12*nside*nside, by: skip) {
                nest2ring(nside, p, &q); ring2nest(nside, q, &r); XCTAssert(r == p)
            }
        }
    }
    
    func test_ang() throws {
        for nside in nsides {
            var skip = nside*nside/maxtries + 1, r = 0
            var theta = 0.0, phi = 0.0
            
            for p in stride(from: 0, to: 12*nside*nside, by: skip) {
                pix2ang_nest(nside, p, &theta, &phi)
                ang2pix_nest(nside, theta, phi, &r)
                XCTAssert(r == p)
                
                pix2ang_ring(nside, p, &theta, &phi)
                ang2pix_ring(nside, theta, phi, &r)
                XCTAssert(r == p)
            }
        }
    }
    
    func test_vec() throws {
        for nside in nsides {
            var skip = nside*nside/maxtries + 1, r = 0
            var v = [0.0, 0.0, 0.0]
            
            for p in stride(from: 0, to: 12*nside*nside, by: skip) {
                v.withUnsafeMutableBufferPointer { v in
                    pix2vec_nest(nside, p, v.baseAddress!)
                    vec2pix_nest(nside, v.baseAddress!, &r)
                }
                XCTAssert(r == p)
                
                v.withUnsafeMutableBufferPointer { v in
                    pix2vec_ring(nside, p, v.baseAddress!)
                    vec2pix_ring(nside, v.baseAddress!, &r)
                }
                XCTAssert(r == p)
            }
        }
    }
}
