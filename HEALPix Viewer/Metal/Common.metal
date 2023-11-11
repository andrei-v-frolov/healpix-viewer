//
//  Common.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-22.
//

#ifndef __COMMON__
#define __COMMON__

// global constants
constant const float     pi = 3.141592653589793238462643383279502884197169399375;
constant const float  twopi = 6.283185307179586476925286766559005768394338798750;
constant const float halfpi = 1.570796326794896619231321691639751442098584699688;
constant const float  sqrt2 = 1.414213562373095048801688724209698078569671875377;
constant const float  sqrt3 = 1.732050807568877293527446341505872366942805253810;
constant const float rsqrt2 = 0.707106781186547524400844362104849039284835937690;
constant const float rsqrt3 = 0.577350269189625764509148780501957455647601751269;

// guard value when (xy) is out of projection range
constant const float3 OUT_OF_BOUNDS = float3(0);

// checkerboard grid colors
constant const float4 DARK_TILE  = float4(0.6, 0.6, 0.6, 1.0);
constant const float4 LIGHT_TILE = float4(0.7, 0.7, 0.7, 1.0);

// zebra pattern colors
constant const float4 ZEBRA_LOW    = float4(0.0, 0.0, 1.0, 1.0);
constant const float4 ZEBRA_HIGH   = float4(1.0, 0.0, 0.0, 1.0);
constant const float4 ZEBRA_STRIPE = float4(1.0, 1.0, 1.0, 1.0);

#endif /* __COMMON__ */
