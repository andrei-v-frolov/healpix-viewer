//
//  Colorcube.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-07.
//

#ifndef __COLORCUBE__
#define __COLORCUBE__

// MARK: color cube projections and cuts
inline float3 lower_face(float2 v) {
    { const float r = (-2.0*rsqrt3)*v.x, g = v.y - rsqrt3*v.x; if (r > 0.0 && g > 0.0) return float3(r,g,0.0); }
    { const float b = (+2.0*rsqrt3)*v.x, g = v.y + rsqrt3*v.x; if (b > 0.0 && g > 0.0) return float3(0.0,g,b); }
    { const float r = -rsqrt3*v.x - v.y, b = rsqrt3*v.x - v.y; if (r > 0.0 && b > 0.0) return float3(r,0.0,b); }
    return float3(0.0);
}

inline float3 upper_face(float2 v) {
    { const float r = (-2.0*rsqrt3)*v.x, g = v.y - rsqrt3*v.x; if (r < 0.0 && g < 0.0) return float3(r,g,0.0)+1.0; }
    { const float b = (+2.0*rsqrt3)*v.x, g = v.y + rsqrt3*v.x; if (b < 0.0 && g < 0.0) return float3(0.0,g,b)+1.0; }
    { const float r = -rsqrt3*v.x - v.y, b = rsqrt3*v.x - v.y; if (r < 0.0 && b < 0.0) return float3(r,0.0,b)+1.0; }
    return float3(1.0);
}

inline float3 plane_cut(float2 v, float u) {
    return float3(u-v.y-sqrt3*v.x, u+2.0*v.y, u-v.y+sqrt3*v.x)/3.0;
}

// MARK: color cube shader kernel
kernel void colorcube(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4 &background         [[ buffer(1) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 v = transform * float3(gid.x, gid.y, 1);
    const float3 rgb = powr(plane_cut(v,2.0), 1.0/2.2);
    
    float4 pixel = select(over(float4(rgb,1), background), background, length(v) > 1.0);
    output.write(pixel, gid);
}

#endif /* __COLORCUBE__ */
