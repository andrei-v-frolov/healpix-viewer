//
//  Colorcube.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-07.
//

#ifndef __COLORCUBE__
#define __COLORCUBE__

// MARK: color cube projections and cuts
inline float3 lower_face(const float2 v) {
    const float x = rsqrt3*v.x, y = v.y;
    return select(select(float3(0.0,y+x,2.0*x), float3(-2.0*x,y-x,0.0), x < 0.0), float3(-x-y,0.0,x-y), y < -fabs(x));
}

inline float3 upper_face(const float2 v) {
    const float x = rsqrt3*v.x, y = v.y;
    return select(select(float3(0.0,y+x,2.0*x), float3(-2.0*x,y-x,0.0), x > 0.0), float3(-x-y,0.0,x-y), y > fabs(x)) + 1.0;
}

inline float3 plane_cut(const float2 v, const float u) {
    return float3(u-v.y-sqrt3*v.x, u+2.0*v.y, u-v.y+sqrt3*v.x)/3.0;
}

// MARK: four-panel color cube cuts
inline float3 four_panel(const float2 u) {
    { const float2 v = u + float2(3.75,0.0); if (length(v) < 1.0) return lower_face(v); }
    { const float2 v = u + float2(1.25,0.0); if (length(v) < 1.0) return plane_cut(v, 1.0); }
    { const float2 v = u - float2(1.25,0.0); if (length(v) < 1.0) return plane_cut(v, 2.0); }
    { const float2 v = u - float2(3.75,0.0); if (length(v) < 1.0) return upper_face(v); }
    return float3(0.0);
}

// MARK: color cube shader kernel
kernel void colorcube(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4x4 &mixer            [[ buffer(1) ]],
    constant float4 &gamma              [[ buffer(2) ]],
    constant float4 &background         [[ buffer(3) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 v = transform * float3(gid.x, gid.y, 1);
    const float4 rgba = mixer*float4(four_panel(v), 1.0);
    const float4 pixel = over(powr(rgba, gamma), background);
    
    output.write(pixel, gid);
}

#endif /* __COLORCUBE__ */
