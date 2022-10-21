//
//  Projections.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-21.
//

#include <metal_stdlib>
using namespace metal;

constant const float pi = 3.14159265358979323846264338327950288419716939938;
constant const float twopi = 6.28318530717958647692528676655900576839433879876;
constant const float halfpi = 1.57079632679489661923132169163975144209858469969;

// guard value when (xy) is out of projection range
constant const float3 OUT_OF_BOUNDS = float3(0);

// convert polar coordinates to 3-vector on a sphere
inline float3 ang2vec(float2 a) {
    float z = cos(a.x), r = sin(a.x);
    return float3(r*cos(a.y),r*sin(a.y),z);
}

// convert 3-vector on a sphere to polar coordinates; phi range is (-pi,pi]
inline float2 vec2ang(float3 v) {
    float phi = atan2(v.y,v.x), theta = atan2(length(v.xy),v.z);
    return float2(theta,phi);
}

// Mollweide projection
inline float3 mollweide(float2 v) {
    float psi = asin(v.y), phi = halfpi*v.x/cos(psi), theta = acos((2.0*psi + sin(2.0*psi))/pi);
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, phi <= -pi || phi > pi);
}

// Gnomonic projection
inline float3 gnomonic(float2 v) {
    return normalize(float3(1.0,v.x,v.y));
}

// Lambert projection
inline float3 lambert(float2 v) {
    float q = 1.0 - (v.x*v.x + v.y*v.y)/4.0;
    return select(float3(2.0*q-1.0,sqrt(q)*v.x,sqrt(q)*v.y), OUT_OF_BOUNDS, q < 0.0);
}

// Isometric projection
inline float3 isometric(float2 v) {
    float x2 = 1.0 - (v.x*v.x + v.y*v.y);
    return select(float3(sqrt(x2),v.x,v.y), OUT_OF_BOUNDS, x2 < 0.0);
}

// Mercator projection
inline float3 mercator(float2 v) {
    float phi = v.x, theta = atan(sinh(v.y)) + halfpi;
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, phi <= -pi || phi > pi);
}
