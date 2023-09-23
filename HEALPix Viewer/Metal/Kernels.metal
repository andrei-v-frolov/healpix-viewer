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
#include "Colorize.metal"
#include "Components.metal"
#include "Transforms.metal"
#include "Projections.metal"

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

#define PROJECTION(variant) orthographic ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) stereographic ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) gnomonic ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) mercator ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) cartesian ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) werner ## variant
#include "Shaders.metal"
#undef PROJECTION
