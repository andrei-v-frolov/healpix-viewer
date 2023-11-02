//
//  Colorize.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

#ifndef __COLORIZE__
#define __COLORIZE__

// MARK: okLab color space
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
    return float4(M1*pow(M2*v.xyz, 3.0), v.w);
}

// MARK: Hybrid log-gamma (Rec. 2100)
// [https://en.wikipedia.org/wiki/Hybrid_log–gamma]

// stretched and scaled to match sqrt(x) at midtones (where average is mapped to)
constant const float HLG_A = 0.19264464123396488699073686524675879;
constant const float HLG_B = 0.28466890937220093748991475372557885;
constant const float HLG_C = 0.60315455422596953825614647615458749;
constant const float HLG_D = 1.07723343082931487010271121247405941;

inline float4 hlg(const float4 v) {
    return float4(select(HLG_A*log(4.0*v.xyz-HLG_B) + HLG_C, HLG_D*sqrt(v.xyz), v.xyz <= 0.25), v.w);
}

// MARK: ACES filmic curve approximation (scaled to prevent clipping)
// [https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/]

inline float4 film(const float4 v) {
    const float3 x = v.xyz;
    return float4((2.43/2.51)*(x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14), v.w);
}

// MARK: ACES gamut compression
// [https://docs.acescentral.com/guides/rgc-implementation/]
// [https://github.com/ampas/aces-dev/blob/master/transforms/ctl/lmt/LMT.Academy.GamutCompress.ctl]

constant const float3 GAMUT_LIM = float3(1.147,1.264,1.312);
constant const float3 GAMUT_THR = float3(0.815,0.803,0.880);
constant const float  GAMUT_PWR = 1.2;

// compression grading curve
inline float3 grade(const float3 dist) {
    const float3 intersect = pow((GAMUT_LIM - GAMUT_THR)/(1.0 - GAMUT_THR), GAMUT_PWR);
    const float3 scale = (GAMUT_LIM - GAMUT_THR)/pow(intersect - 1.0, 1.0/GAMUT_PWR);
    const float3 x = (dist - GAMUT_THR)/scale;
    
    return select(GAMUT_THR + scale*x/pow(1.0 + pow(x, GAMUT_PWR), 1.0/GAMUT_PWR), dist, dist < GAMUT_THR);
}

inline float4 compress(const float4 v) {
    const float a = max3(v.x,v.y,v.z);
    const float3 dist = select((a-v.xyz)/fabs(a), float3(0.0), a == 0.0);
    
    return float4(a - grade(dist)*fabs(a), v.w);
}

// MARK: composite A over B
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

// MARK: colormix 3-channel data to texture array
kernel void colormix_clip(
    texture2d_array<float,access::write> output [[ texture(0) ]],
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant float4x4 &mixer            [[ buffer(3) ]],
    constant float4 &gamma              [[ buffer(4) ]],
    constant float4 &nan                [[ buffer(5) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    const int p = xyf2nest(output.get_width(), int3(gid));
    const float4 v = float4(x[p],y[p],z[p],1.0);
    
    output.write(select(powr(mixer*v, gamma), nan, any(isnan(v) or isinf(v))), gid.xy, gid.z);
}

kernel void colormix_comp(
    texture2d_array<float,access::write> output [[ texture(0) ]],
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant float4x4 &mixer            [[ buffer(3) ]],
    constant float4 &gamma              [[ buffer(4) ]],
    constant float4 &nan                [[ buffer(5) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    const int p = xyf2nest(output.get_width(), int3(gid));
    const float4 v = float4(x[p],y[p],z[p],1.0);
    
    output.write(select(powr(film(compress(mixer*v)), gamma), nan, any(isnan(v) or isinf(v))), gid.xy, gid.z);
}

kernel void colormix_clab(
    texture2d_array<float,access::write> output [[ texture(0) ]],
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant float4x4 &mixer            [[ buffer(3) ]],
    constant float4 &gamma              [[ buffer(4) ]],
    constant float4 &nan                [[ buffer(5) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    const int p = xyf2nest(output.get_width(), int3(gid));
    const float4 v = ok2lrgb(mixer*float4(x[p],y[p],z[p],1.0));
    
    output.write(select(powr(v, gamma), nan, any(isnan(v) or isinf(v))), gid.xy, gid.z);
}

kernel void colormix_film(
    texture2d_array<float,access::write> output [[ texture(0) ]],
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant float4x4 &mixer            [[ buffer(3) ]],
    constant float4 &gamma              [[ buffer(4) ]],
    constant float4 &nan                [[ buffer(5) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    const int p = xyf2nest(output.get_width(), int3(gid));
    const float4 v = ok2lrgb(mixer*float4(x[p],y[p],z[p],1.0));
    
    output.write(select(powr(film(compress(v)), gamma), nan, any(isnan(v) or isinf(v))), gid.xy, gid.z);
}

// MARK: accumulate covariance of 3-channel data
kernel void covariance(
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    device uint *pts                    [[ buffer(3) ]],
    device float3x3 *cov                [[ buffer(4) ]],
    constant float2x3 &range            [[ buffer(5) ]],
    constant uint2 &npix                [[ buffer(6) ]],
    uint tid                            [[ thread_position_in_grid ]],
    uint width                          [[ threads_per_grid ]]
) {
    // thread-local accumulators
    float3x3 A = float3x3(0.0); uint n = 0;
    
    // accumulate all the pixels in this thread
    for (uint i = tid << npix.y; i < npix.x; i += width << npix.y) {
        const float3 v = float3(x[i],y[i],z[i]);
        if (any(isnan(v) or isinf(v) or (v < range[0]) or (v > range[1]))) { continue; }
        A += float3x3(v, float3(v.x*v.x,v.y*v.y,v.z*v.z), float3(v.x*v.y,v.x*v.z,v.y*v.z)); n++;
    }
    
    // store to shared buffer
    cov[tid] = A; pts[tid] = n;
    
    // hierarchical reduce
    for (uint s = width/2; s > 0; s >>= 1) {
        threadgroup_barrier(mem_flags::mem_device);
        if (tid < s) { cov[tid] += cov[tid+s]; pts[tid] += pts[tid+s]; }
    }
}

#endif /* __COLORIZE__ */
