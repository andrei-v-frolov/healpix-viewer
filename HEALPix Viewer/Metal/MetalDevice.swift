//
//  MetalDevice.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-24.
//

import Foundation
import MetalKit

let metal = MetalDevice()

final class MetalDevice {
    let device: MTLDevice
    let queue: MTLCommandQueue
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue()
              else { abort("Metal framework could not be initalized") }
        
        self.device = device
        self.queue = queue
    }
}
