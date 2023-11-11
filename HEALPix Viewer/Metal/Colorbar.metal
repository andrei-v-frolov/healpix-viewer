//
//  Colorbar.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-02.
//

#ifndef __COLORBAR__
#define __COLORBAR__

// MARK: zebra pattern for out-of-bounds pixels
inline float4 zebra(const float4 v, const float alpha, const uint idx) {
    if (all(v.xyz > 1.0)) { return over(alpha*select(ZEBRA_HIGH, ZEBRA_STRIPE, idx & 0b1000), v); }
    if (all(v.xyz < 0.0)) { return over(alpha*select(ZEBRA_LOW,  ZEBRA_STRIPE, idx & 0b1000), v); }
    return v;
}

// MARK: colorbar shader kernel
kernel void colorbar(
    texture1d<float,access::sample>     palette [[ texture(0) ]],
    texture2d<float,access::write>      output [[ texture(1) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4 &background         [[ buffer(1) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 v = transform * float3(gid.x, gid.y, 1);
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    output.write(select(over(palette.sample(s, v.x), background), background, v.x < 0.0 | v.x > 1.0 | v.y < 0.0 | v.y > 1.0), gid);
}

// MARK: colorbar composed over backing grid
kernel void colorbar_grid(
    texture1d<float,access::sample>     palette [[ texture(0) ]],
    texture2d<float,access::write>      output [[ texture(1) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4 &background         [[ buffer(1) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 v = transform * float3(gid.x, gid.y, 1);
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    const float4 tile = select(LIGHT_TILE, DARK_TILE, int(4*transform[1][1]/transform[0][0]*v.x)+int(4*v.y) & 0x01);
    
    output.write(select(over(palette.sample(s, v.x), tile), background, v.x < 0.0 | v.x > 1.0 | v.y < 0.0 | v.y > 1.0), gid);
}

// MARK: colorbar composed over backing grid
kernel void colorbar_zebra(
    texture1d<float,access::sample>     palette [[ texture(0) ]],
    texture2d<float,access::write>      output [[ texture(1) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float4 &background         [[ buffer(1) ]],
    constant float &alpha               [[ buffer(2) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 v = transform * float3(gid.x, gid.y, 1);
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    const float4 tile = select(LIGHT_TILE, DARK_TILE, int(4*transform[1][1]/transform[0][0]*v.x)+int(4*v.y) & 0x01);
    
    output.write(select(over(zebra(palette.sample(s, v.x), alpha, gid.x+gid.y), tile), background, v.x < 0.0 | v.x > 1.0 | v.y < 0.0 | v.y > 1.0), gid);
}

#endif /* __COLORBAR__ */
