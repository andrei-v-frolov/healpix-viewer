//
//  Kernels.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-20.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;

// include Metal functions
#include "Common.metal"
#include "Healpix.metal"
#include "Transforms.metal"
#include "Projections.metal"

// checkerboard grid colors
constant const float4 DARK_TILE  = float4(0.6, 0.6, 0.6, 1.0);
constant const float4 LIGHT_TILE = float4(0.7, 0.7, 0.7, 1.0);

// checkerboard grid on spherical coordinates
inline float4 grid(float2 ang) {
    const int2 b = int2(floor(8.0/halfpi * ang));
    return select(LIGHT_TILE, DARK_TILE, (b.x+b.y) & 0x01);
}

// lighting effect applied from a particular direction
inline float4 lighted(float4 pixel, float4 light, float3 v) {
    return select(float4(pow(1.0 + light.w * (dot(light.xyz, v)-1.0)/2.0, 0.45454545)*pixel.xyz, pixel.w), pixel, light.w == 0.0);
}

// MARK: shader kernels for all projections
#define PROJECTION(variant) mollweide ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) hammer ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) lambert ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) isometric ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) gnomonic ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) mercator ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) cylindrical ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) werner ## variant
#include "Shaders.metal"
#undef PROJECTION

// MARK: colorbar shader kernel
kernel void colorbar(
    texture1d<float,access::sample>     palette [[ texture(0) ]],
    texture2d<float,access::write>      output [[ texture(1) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4 &background         [[ buffer(1) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 v = transform * float3(gid.x, gid.y, 1);
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    float4 pixel = select(palette.sample(s, v.x), background, v.x < 0.0 | v.x > 1.0 | v.y < 0.0 | v.y > 1.0);
    output.write(pixel, gid);
}
