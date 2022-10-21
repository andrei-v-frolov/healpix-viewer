//
//  Common.h
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-21.
//

#ifndef Common_h
#define Common_h

// global constants
constant const float pi = 3.14159265358979323846264338327950288419716939938;
constant const float twopi = 6.28318530717958647692528676655900576839433879876;
constant const float halfpi = 1.57079632679489661923132169163975144209858469969;

// guard value when (xy) is out of projection range
constant const float3 OUT_OF_BOUNDS = float3(0);

// projection functions
inline float3 ang2vec(float2 a);
inline float2 vec2ang(float3 v);

inline float3 mollweide(float2 v);
inline float3 gnomonic(float2 v);
inline float3 lambert(float2 v);
inline float3 isometric(float2 v);
inline float3 mercator(float2 v);

#endif /* Common_h */
