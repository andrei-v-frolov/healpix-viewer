//
//  Curves.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-17.
//

#define VARIANT(name) GAMUT(name ## _clip)
#define CURVE(v) saturate(v)
#include "Mixers.metal"
#undef CURVE
#undef VARIANT

#define VARIANT(name) GAMUT(name ## _film)
#define CURVE(v) film(max(v,0.0))
#include "Mixers.metal"
#undef CURVE
#undef VARIANT

#define VARIANT(name) GAMUT(name ## _hlg)
#define CURVE(v) hlg(max(v,0.0))
#include "Mixers.metal"
#undef CURVE
#undef VARIANT

#define VARIANT(name) GAMUT(name ## _hdr)
#define CURVE(v) max(v,0.0)
#include "Mixers.metal"
#undef CURVE
#undef VARIANT
