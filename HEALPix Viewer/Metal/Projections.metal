//
//  Projections.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-21.
//

#ifndef __PROJECTIONS__
#define __PROJECTIONS__

// convert polar coordinates to 3-vector on a sphere
inline float3 ang2vec(float2 a) {
    const float z = cos(a.x), r = sin(a.x);
    return float3(r*cos(a.y),r*sin(a.y),z);
}

// convert 3-vector on a sphere to polar coordinates; phi range is (-pi,pi]
inline float2 vec2ang(float3 v) {
    const float phi = atan2(v.y,v.x), theta = atan2(length(v.xy),v.z);
    return float2(theta,phi);
}

// Mollweide projection
inline float3 mollweide(float2 v) {
    const float psi = asin(v.y), phi = halfpi*v.x/cos(psi), theta = acos((2.0*psi + sin(2.0*psi))/pi);
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, v.y < -1.0 || v.y > 1.0 || phi < -pi || phi > pi);
}

// Hammer-Aitoff projection
inline float3 hammer(float2 v) {
    const float p = v.x*v.x/4.0 + v.y*v.y, q = 1.0 - p/4.0, z = sqrt(q);
    const float theta = acos(z*v.y), phi = 2.0*atan(z*v.x/(2.0*q-1.0)/2.0);
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, p > 2.0);
}

// Lambert projection
inline float3 lambert(float2 v) {
    const float q = 1.0 - (v.x*v.x + v.y*v.y)/4.0;
    return select(float3(2.0*q-1.0,sqrt(q)*v.x,sqrt(q)*v.y), OUT_OF_BOUNDS, q < 0.0);
}

// Isometric (aka orthographic) projection
inline float3 orthographic(float2 v) {
    const float q = 1.0 - (v.x*v.x + v.y*v.y);
    return select(float3(sqrt(q),v.x,v.y), OUT_OF_BOUNDS, q < 0.0);
}

// Stereographic projection
inline float3 stereographic(float2 v) {
    return 4.0/(4.0+v.x*v.x+v.y*v.y) * float3(2.0,v.x,v.y) - float3(1,0,0);
}

// Gnomonic projection
inline float3 gnomonic(float2 v) {
    return normalize(float3(1.0,v.x,v.y));
}

// Mercator projection
inline float3 mercator(float2 v) {
    const float phi = v.x, theta = halfpi - atan(sinh(v.y));
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, phi < -pi || phi > pi);
}

// Equirectangular (aka cylindrical) projection
inline float3 cartesian(float2 v) {
    const float phi = v.x, theta = halfpi - v.y;
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, phi < -pi || phi > pi || theta < 0.0 || theta > pi);
}

// Werner projection
inline float3 werner(float2 v) {
    const float2 u = v - float2(0,1.111983413);
    const float theta = length(u), phi = theta/sin(theta)*atan2(u.x,-u.y);
    return select(ang2vec(float2(theta,phi)), OUT_OF_BOUNDS, theta > pi || phi < -pi || phi > pi);
}

#endif /* __PROJECTIONS__ */
