//
//  Components.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-07-26.
//

#ifndef __COMPONENTS__
#define __COMPONENTS__

// MARK: best fit to specified spectral model
kernel void component(
    constant float *a                   [[ buffer(0) ]],
    constant float *b                   [[ buffer(1) ]],
    constant float *c                   [[ buffer(2) ]],
    constant float3 &units              [[ buffer(3) ]],
    constant float3x3 &model            [[ buffer(4) ]],
    device float *component             [[ buffer(5) ]],
    uint tid                            [[ thread_position_in_grid ]]
) {
    const float3 d = float3(a[tid],b[tid],c[tid])*units;
    float3 x = 0, g = d*model; float eta = 0.1;
    
    // Barzilai-Borwein optimizer
    for (int i = 0; i < 16; i++) {
        const float3 deltaX = eta*g; x += deltaX;
        const float3 grad = (d-model*x) * model;
        const float3 deltaG = g-grad; g = grad;
        eta = min(dot(deltaX,deltaX)/dot(deltaX,deltaG), dot(deltaX,deltaG)/dot(deltaG,deltaG));
    }
    
    x += eta*g; component[tid] = length(d-model*x)/length(d);
}

#endif /* __COMPONENTS__ */
