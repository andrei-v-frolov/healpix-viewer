//
//  Components.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-26.
//

#ifndef __COMPONENTS__
#define __COMPONENTS__

// MARK: internal linear combination
// minimize x.C.x subject to constraint w.x = 1, pivoted around middle
inline float3 ilc(const float3 C1, const float3 C2, const float3 w) {
    const float3 v = float3(w.x,1,w.z)/w.y;
    const float a = C1.x - 2.0*C2.x*v.x + C1.y*v.x*v.x;
    const float d = C1.z - 2.0*C2.z*v.z + C1.y*v.z*v.z;
    const float b = C2.y - C2.x*v.z - C2.z*v.x + C1.y*v.x*v.z;
    const float e = (C2.x-C1.y*v.x)*v.y;
    const float f = (C2.z-C1.y*v.z)*v.y;
    const float det = a*d-b*b;
    
    const float alpha = (b*f-d*e)/det;
    const float gamma = (b*e-a*f)/det;
    const float beta = v.y - v.x*alpha - v.z*gamma;
    return float3(alpha,beta,gamma);
}

// MARK: accumulate block covariance of 3-channel data
kernel void block_cov(
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant uint2 &nside               [[ buffer(3) ]],
    device float *cov                   [[ buffer(4) ]],
    uint tid                            [[ thread_position_in_grid ]]
) {
    // block-local accumulators
    float3x3 A = float3x3(0.0); uint n = 0;
    
    // accumulate all the pixels in this block
    for (uint i = tid << nside.y; i < (tid+1) << nside.y; i++) {
        const float3 v = float3(x[i],y[i],z[i]); if (any(isnan(v) or isinf(v))) { continue; }
        A += float3x3(v, float3(v.x*v.x,v.y*v.y,v.z*v.z), float3(v.x*v.y,v.x*v.z,v.y*v.z)); n++;
    }
    
    // covariance via König's formula (not the best way, but good enough)
    const uint k = tid*6; A /= n;
    cov[k+0] = A[1][0] - A[0].x*A[0].x;
    cov[k+1] = A[1][1] - A[0].y*A[0].y;
    cov[k+2] = A[1][2] - A[0].z*A[0].z;
    cov[k+3] = A[2][0] - A[0].x*A[0].y;
    cov[k+4] = A[2][1] - A[0].x*A[0].z;
    cov[k+5] = A[2][2] - A[0].y*A[0].z;
}

// MARK: compute block ILC coefficients
kernel void block_ilc(
    texture2d_array<float,access::write> coefficients [[ texture(0) ]],
    constant float *cov                 [[ buffer(0) ]],
    constant float4 &weight             [[ buffer(1) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    const int p = xyf2nest(coefficients.get_width(), int3(gid))*6;
    const float3 x = ilc(weight.w*float3(cov[p+0],cov[p+1],cov[p+2]), float3(cov[p+3],cov[p+4],cov[p+5]), weight.xyz);
    coefficients.write(float4(x,1.0), gid.xy, gid.z);
}

// MARK: separate component using interpolated ILC coefficients
kernel void separate(
    texture2d_array<float,access::sample> coefficients [[ texture(0) ]],
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant uint2 &nside               [[ buffer(3) ]],
    device float *data                  [[ buffer(4) ]],
    uint tid                            [[ thread_position_in_grid ]]
) {
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    const int3 xyf = nest2xyf(nside.x, tid);
    const float4 w = coefficients.sample(s, float2(xyf.xy)/(nside.x-1), xyf.z);
    data[tid] = w.x*x[tid] + w.y*y[tid] + w.z*z[tid];
}

#endif /* __COMPONENTS__ */
