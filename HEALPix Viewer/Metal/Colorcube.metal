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

// MARK: three-panel color cube cuts
inline float3 three_panel(const float2 u) {
    if (length(u) < 1.0) return plane_cut(u, 1.5);
    { const float2 v = u + float2(2.5,0.0); if (length(v) < 1.0) return lower_face(v); }
    { const float2 v = u - float2(2.5,0.0); if (length(v) < 1.0) return upper_face(v); }
    return INVALID;
}

#endif /* __COLORCUBE__ */
