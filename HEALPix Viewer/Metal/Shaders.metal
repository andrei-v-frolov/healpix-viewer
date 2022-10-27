//
//  Shaders.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-27.
//

// MARK: grid kernels template
kernel void PROJECTION(_grid)(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float3x3 &rotation         [[ buffer(1) ]],
    constant float4 &background         [[ buffer(2) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float3 v = rotation * PROJECTION()(transform * float3(gid.x, gid.y, 1));
    
    float4 pixel = select(grid(vec2ang(v)), background, all(v == OUT_OF_BOUNDS));
    output.write(pixel, gid);
}
