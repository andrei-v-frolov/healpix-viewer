//
//  Colorize.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-19.
//

#ifndef __COLORIZE__
#define __COLORIZE__

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
kernel void colormix(
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
    
    output.write(select(powr(saturate(mixer*v), gamma), nan, any(isnan(v)) or any(isinf(v))), gid.xy, gid.z);
}

// MARK: accumulate covariance of 3-channel data
kernel void covariance(
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    device uint *pts                    [[ buffer(3) ]],
    device float3 *avg                  [[ buffer(4) ]],
    device float3x3 *cov                [[ buffer(5) ]],
    constant float2x3 &range            [[ buffer(6) ]],
    constant uint2 &npix                [[ buffer(7) ]],
    uint tid                            [[ thread_position_in_grid ]],
    uint width                          [[ threads_per_grid ]]
) {
    // thread-local accumulators
    uint n = 0; float3 A = 0.0; float3x3 C = float3x3(0.0, 0.0, 0.0);
    
    // accumulate all the pixels in this thread
    for (uint i = tid << npix.y; i < npix.x; i += width << npix.y) {
        const float3 v = float3(x[i],y[i],z[i]);
        if (any(isnan(v)) or any(isinf(v)) or any(v < range[0]) or any(v > range[1])) { continue; }
        
        n++; A += v; C += float3x3(
            float3(v.x*v.x,v.y*v.x,v.z*v.x),
            float3(v.x*v.y,v.y*v.y,v.z*v.y),
            float3(v.x*v.z,v.y*v.z,v.z*v.z)
        );
    }
    
    // store to shared buffer
    pts[tid] = n; avg[tid] = A; cov[tid] = C;
    
    // hierarchical reduce
    for (uint s = width/2; s > 0; s >>= 1) {
        threadgroup_barrier(mem_flags::mem_device);
        if (tid < s) { pts[tid] += pts[tid+s]; avg[tid] += avg[tid+s]; cov[tid] += cov[tid+s]; }
    }
}

#endif /* __COLORIZE__ */
