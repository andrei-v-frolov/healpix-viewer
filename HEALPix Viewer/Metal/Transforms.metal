//
//  Transforms.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-26.
//

#ifndef __TRANSFORMS__
#define __TRANSFORMS__

// MARK: erfinv from Mike Giles
inline float erfinv(float x) {
    float w = -log((1.0-x)*(1.0+x)), p;
    
    if (w < 5.0) {
        w = w - 2.5;
        p =  2.81022636e-08;
        p =  3.43273939e-07 + p*w;
        p = -3.5233877e-06  + p*w;
        p = -4.39150654e-06 + p*w;
        p=   0.00021858087  + p*w;
        p = -0.00125372503  + p*w;
        p = -0.00417768164  + p*w;
        p =  0.246640727    + p*w;
        p =  1.50140941     + p*w;
    } else {
        w = sqrt(w) - 3.0;
        p = -0.000200214257;
        p =  0.000100950558 + p*w;
        p =  0.00134934322  + p*w;
        p = -0.00367342844  + p*w;
        p =  0.00573950773  + p*w;
        p = -0.0076224613   + p*w;
        p =  0.00943887047  + p*w;
        p =  1.00167406     + p*w;
        p =  2.83297682     + p*w;
    }
    
    return p*x;
}

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

kernel void pow_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    const float x = input[gid] - param.x;
    output[gid] = copysign(pow(abs(x), param.y), x);
}

kernel void exp_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    output[gid] = exp((input[gid] - param.x)/param.y);
}

kernel void norm_transform(
    constant float *input               [[ buffer(0) ]],
    device float *output                [[ buffer(1) ]],
    constant float2 &param              [[ buffer(2) ]],
    uint gid                            [[ thread_position_in_grid ]]
) {
    output[gid] = sqrt2 * erfinv(2.0*input[gid]-1.0);
}

#endif /* __TRANSFORMS__ */
