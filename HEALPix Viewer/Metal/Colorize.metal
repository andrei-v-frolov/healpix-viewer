//
//  Colorize.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

#ifndef __COLORIZE__
#define __COLORIZE__

// MARK: okLab color space
// [https://bottosson.github.io/posts/oklab/]
constant const float3x3 M1 = {
    float3( 4.07675841355650,  -1.26818108516240, -0.00409840771803133),
    float3(-3.30722798739447,   2.60929321028564, -0.703503660102417),
    float3( 0.230721459944886, -0.341112116547754, 1.70686045297880)
};

constant const float3x3 M2 = {
    float3(1.0),
    float3(0.396337792173768, -0.105561342323656,  -0.0894841820949657),
    float3(0.215803758060759, -0.0638541747717059, -1.29148553786409)
};

inline float4 ok2lrgb(const float4 v) {
    return float4(M1*pow(M2*v.xyz, 3), v.w);
}

// MARK: ACES reference gamut compression
// [https://docs.acescentral.com/guides/rgc-implementation/]
// [https://github.com/ampas/aces-dev/blob/master/transforms/ctl/lmt/LMT.Academy.GamutCompress.ctl]

constant const float  GAMUT_PWR = 1.2;
constant const float3 GAMUT_THR = float3(0.815,0.803,0.880);
// constant const float3 GAMUT_LIM = float3(1.147,1.264,1.312);

// auxilliary pre-computed parameters
// constant const float3 GAMUT_INT = pow((GAMUT_LIM - GAMUT_THR)/(1.0 - GAMUT_THR), GAMUT_PWR);
// constant const float3 GAMUT_SCL = (GAMUT_LIM - GAMUT_THR)/pow(GAMUT_INT - 1.0, 1.0/GAMUT_PWR);
constant const float3 GAMUT_SCL = float3(0.3273018774677787, 0.2859380289271138, 0.1468214578384229);

// compression grading curve
inline float3 grade(const float3 dist) {
    const float3 scale = pow(1.0 + pow((dist - GAMUT_THR)/GAMUT_SCL, GAMUT_PWR), -1.0/GAMUT_PWR);
    return select(GAMUT_THR + scale*(dist - GAMUT_THR), dist, dist < GAMUT_THR);
}

inline float4 acesrgc(const float4 v) {
    const float a = max3(v.x,v.y,v.z);
    const float3 dist = select((a-v.xyz)/fabs(a), 0.0, a == 0.0);
    
    return float4(a-grade(dist)*fabs(a), v.w);
}

// MARK: ACES filmic curve approximation (scaled to prevent highlight clipping)
// [https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/]

inline float4 film(const float4 v) {
    const float3 x = v.xyz;
    return float4((2.43/2.51)*(x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14), v.w);
}

// MARK: linearized Hybrid log-gamma (Rec. 2100)
// [https://en.wikipedia.org/wiki/Hybrid_log–gamma]

// stretched and scaled to match midtones (where average is mapped to)
constant const float HLG_A = 0.19264464123396488699073686524675879;
constant const float HLG_B = 0.28466890937220093748991475372557885;
constant const float HLG_C = 0.60315455422596953825614647615458749;
constant const float HLG_D = 1.16043186449629630482925925719925639;

inline float4 hlg(const float4 v) {
    const float3 x = v.xyz;
    return float4(select(powr(HLG_A*log(4.0*x-HLG_B) + HLG_C, 2), HLG_D*x, x <= 0.25), v.w);
}

// MARK: pre-multiplied transparency composite A over B
inline float4 over(const float4 a, const float4 b) { return a + (1.0-a.w)*b; }

// MARK: colormap data to texture array
kernel void colorize(
    texture1d<float,access::sample>     palette [[ texture(0) ]],
    texture2d_array<float,access::write> output [[ texture(1) ]],
    constant float *data                [[ buffer(0) ]],
    constant float3x4 &colors           [[ buffer(1) ]],
    constant float2 &range              [[ buffer(2) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    const int p = xyf2nest(output.get_width(), int3(gid));
    const float v = (data[p] - range.x)/(range.y - range.x);
    
    if (isnan(v) or isinf(v)) { output.write(colors[2], gid.xy, gid.z); return; }
    if (v < 0.0) { output.write(colors[0], gid.xy, gid.z); return; }
    if (v > 1.0) { output.write(colors[1], gid.xy, gid.z); return; }
    
    output.write(palette.sample(s, v), gid.xy, gid.z);
}

// MARK: color scale annotations
#include "Colorbar.metal"
#include "Colorcube.metal"

// MARK: color mixing kernel variants
#define GAMUT(name) rgb ## name
#define RGBA(v) pow(v, 3)
#include "Curves.metal"
#undef RGBA
#undef GAMUT

#define GAMUT(name) crgb ## name
#define RGBA(v) acesrgc(pow(v, 3))
#include "Curves.metal"
#undef RGBA
#undef GAMUT

#define GAMUT(name) lab ## name
#define RGBA(v) ok2lrgb(v)
#include "Curves.metal"
#undef RGBA
#undef GAMUT

#define GAMUT(name) clab ## name
#define RGBA(v) acesrgc(ok2lrgb(v))
#include "Curves.metal"
#undef RGBA
#undef GAMUT

#endif /* __COLORIZE__ */
