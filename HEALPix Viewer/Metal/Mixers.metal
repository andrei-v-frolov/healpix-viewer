//
//  Mixers.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-14.
//

// MARK: mix 3-channel data to color texture array
kernel void VARIANT(mix)(
    texture2d_array<float,access::write> output [[ texture(0) ]],
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    constant float4x4 &mixer            [[ buffer(3) ]],
    constant float4 &gamma              [[ buffer(4) ]],
    constant float4 &nan                [[ buffer(5) ]],
    uint3 gid                           [[ thread_position_in_grid ]]
) {
    const int i = xyf2nest(output.get_width(), int3(gid));
    const float4 v = RGBA(mixer*float4(x[i],y[i],z[i],1.0));
    
    output.write(select(powr(CURVE(v), gamma), nan, any(isnan(v) or isinf(v))), gid.xy, gid.z);
}

// MARK: color cube shader kernel
kernel void VARIANT(cube)(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4x4 &mixer            [[ buffer(1) ]],
    constant float4 &gamma              [[ buffer(2) ]],
    constant float4 &background         [[ buffer(3) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float3 v = three_panel(transform * float3(gid.x, gid.y, 1));
    if (any(isinf(v))) { output.write(background, gid); return; }
    
    const float4 p = RGBA(mixer*float4(v, 1.0));
    if (any(p < 0.0 || p > 1.0)) { output.write(select(LIGHT_TILE, DARK_TILE, ((gid.x >> 4) + (gid.y >> 4)) & 0x01), gid); return; }
    
    output.write(over(powr(CURVE(p), gamma), background), gid);
}
