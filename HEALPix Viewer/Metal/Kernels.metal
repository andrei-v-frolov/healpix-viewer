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

// MARK: shader kernels for all projections
#define PROJECTION(variant) mollweide ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) gnomonic ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) lambert ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) isometric ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) mercator ## variant
#include "Shaders.metal"
#undef PROJECTION

#define PROJECTION(variant) werner ## variant
#include "Shaders.metal"
#undef PROJECTION
