//
//  Kernels.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-20.
//

#include <metal_stdlib>
using namespace metal;

// MARK: test kernel
kernel void uniform_fill(
    texture2d<float,access::write>      output [[ texture(0) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    float4 pixel = float4(1.0, 0.0, 0.0, 0.5);
    output.write(pixel, gid);
}
