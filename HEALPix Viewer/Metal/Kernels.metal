//
//  Kernels.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-20.
//

#include <metal_stdlib>
using namespace metal;

// include Metal functions
#include "Common.metal"
#include "Healpix.metal"
#include "Projections.metal"

// checkerboard grid colors
constant const float4 DARK_TILE  = float4(0.6, 0.6, 0.6, 1.0);
constant const float4 LIGHT_TILE = float4(0.7, 0.7, 0.7, 1.0);

// checkerboard grid on spherical coordinates
inline float4 grid(float2 ang) {
    const int2 b = int2(floor(8.0/halfpi * ang));
    return select(LIGHT_TILE, DARK_TILE, (b.x+b.y) & 0x01);
}

// MARK: grid kernels
kernel void mollweide_grid(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float3x3 &rotation         [[ buffer(1) ]],
    constant float4 &background         [[ buffer(2) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float3 v = rotation * mollweide(transform * float3(gid.x, gid.y, 1));
    
    float4 pixel = select(grid(vec2ang(v)), background, all(v == OUT_OF_BOUNDS));
    output.write(pixel, gid);
}
