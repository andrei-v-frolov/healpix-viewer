//
//  Common.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-22.
//

#ifndef __COMMON__
#define __COMMON__

// global constants
constant const float pi = 3.14159265358979323846264338327950288419716939938;
constant const float twopi = 6.28318530717958647692528676655900576839433879876;
constant const float halfpi = 1.57079632679489661923132169163975144209858469969;
constant const float sqrt2 = 1.414213562373095048801688724209698078569671875377;
constant const float sqrt3 = 1.732050807568877293527446341505872366942805253810;

// guard value when (xy) is out of projection range
constant const float3 OUT_OF_BOUNDS = float3(0);

// checkerboard grid colors
constant const float4 DARK_TILE  = float4(0.6, 0.6, 0.6, 1.0);
constant const float4 LIGHT_TILE = float4(0.7, 0.7, 0.7, 1.0);

// zebra pattern colors
constant const float4 ZEBRA_LOW    = float4(0.0, 0.0, 1.0, 1.0)*0.3;
constant const float4 ZEBRA_HIGH   = float4(1.0, 0.0, 0.0, 1.0)*0.3;
constant const float4 ZEBRA_STRIPE = float4(1.0, 1.0, 1.0, 1.0)*0.3;

#endif /* __COMMON__ */
