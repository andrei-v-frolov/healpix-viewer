//
//  Shaders.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-27.
//

// MARK: grid kernels template
kernel void PROJECTION(_grid)(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float3x3 &rotation         [[ buffer(1) ]],
    constant float4 &background         [[ buffer(2) ]],
    constant float4 &light              [[ buffer(3) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float3 v = rotation * PROJECTION()(transform * float3(gid.x, gid.y, 1));
    
    float4 pixel = select(grid(vec2ang(v)), background, all(v == OUT_OF_BOUNDS));
    output.write(lighted(pixel, light, v), gid);
}

// MARK: data kernels template
kernel void PROJECTION(_data)(
    texture2d_array<float,access::read> map    [[ texture(0) ]],
    texture2d<float,access::write>      output [[ texture(1) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    constant float3x3 &rotation         [[ buffer(1) ]],
    constant float4 &background         [[ buffer(2) ]],
    constant float4 &light              [[ buffer(3) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float3 v = rotation * PROJECTION()(transform * float3(gid.x, gid.y, 1));
    
    if (all(v == OUT_OF_BOUNDS)) {
        output.write(background, gid);
    } else {
        const uint3 f = uint3(xyz2xyf(map.get_width(), v));
        output.write(lighted(map.read(f.xy, f.z), light, v), gid);
    }
}
