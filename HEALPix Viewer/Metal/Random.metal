//
//  Random.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-31.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.metal"

// Random123 library [https://github.com/DEShawResearch/random123]
#include "../../random123/include/Random123/threefry.h"

// MARK: fill data buffer with uniformly distributed random numbers
kernel void random_uniform(
    constant uint &seed                 [[ buffer(0) ]],
    device float4 *data                 [[ buffer(1) ]],
    uint tid                            [[ thread_position_in_grid ]]
) {
    threefry4x32_key_t k = {{tid,  0xdecafbad, 0xfacebead, 0x12345678}};
    threefry4x32_ctr_t c = {{seed, 0xf00dcafe, 0xdeadbeef, 0xbeeff00d}};
    union { threefry4x32_ctr_t c; uint4 i; } u; u.c = threefry4x32(c, k);
    
    data[tid] = float4(u.i)/((float) UINT_MAX);
}

// MARK: fill data buffer with Gaussian random numbers
kernel void random_gaussian(
    constant uint &seed                 [[ buffer(0) ]],
    device float4 *data                 [[ buffer(1) ]],
    uint tid                            [[ thread_position_in_grid ]]
) {
    threefry4x32_key_t k = {{tid,  0xdecafbad, 0xfacebead, 0x12345678}};
    threefry4x32_ctr_t c = {{seed, 0xf00dcafe, 0xdeadbeef, 0xbeeff00d}};
    union { threefry4x32_ctr_t c; uint4 i; } u; u.c = threefry4x32(c, k);
    
    const float4 v = float4(u.i)/((float) UINT_MAX);
    const float2 a = sqrt(-2.0*log(v.xz)), theta = twopi*v.yw;
    data[tid] = float4(a*cos(theta), a*sin(theta));
}
