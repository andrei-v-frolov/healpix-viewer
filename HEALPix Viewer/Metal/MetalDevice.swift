//
//  MetalDevice.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-06-24.
//

import Foundation
import MetalKit

let metal = MetalDevice()
let maxTextureSize = 1 << 14

final class MetalDevice {
    let device: MTLDevice
    let queue: MTLCommandQueue
    
    init() {
        guard let device = PreferredGPU.value.device,
              let queue = device.makeCommandQueue()
              else { abort("Metal framework could not be initalized") }
        
        self.device = device
        self.queue = queue
    }
}
