//
//  Transforms.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-26.
//

#ifndef __TRANSFORMS__
#define __TRANSFORMS__

// MARK: pointwise data transforms
kernel void log_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    output[gid] = log(input[gid] - param.x);
}

kernel void asinh_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    output[gid] = asinh((input[gid] - param.x)/param.y);
}

kernel void atan_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    output[gid] = atan((input[gid] - param.x)/param.y);
}

kernel void tanh_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    output[gid] = tanh((input[gid] - param.x)/param.y);
}

#endif /* __TRANSFORMS__ */
