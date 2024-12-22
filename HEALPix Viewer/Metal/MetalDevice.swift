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
    let maxTextureSize: Int
    
    init() {
        guard let device = PreferredGPU.value.device,
              let queue = device.makeCommandQueue()
              else { abort("Metal framework could not be initalized") }
        
        self.device = device; self.queue = queue
        maxTextureSize = device.supportsFamily(.apple3) ? 1 << 14 : 1 << 13
    }
}
