//
//  Reductions.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-11.
//

#ifndef __REDUCTIONS__
#define __REDUCTIONS__

// MARK: accumulate covariance of 3-channel data
kernel void covariance(
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant float2x3 &range            [[ buffer(3) ]],
    constant uint2 &npix                [[ buffer(4) ]],
    device float3x3 *cov                [[ buffer(5) ]],
    device uint *pts                    [[ buffer(6) ]],
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

#endif /* __REDUCTIONS__ */
