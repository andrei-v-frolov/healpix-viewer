//
//  Healpix.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-21.
//  Code adopted from HEALPix (chealpix.c)
//  Copyright (C) 1997-2016 Krzysztof M. Gorski, Eric Hivon, Martin Reinecke,
//                          Benjamin D. Wandelt, Anthony J. Banday,
//                          Matthias Bartelmann, Reza Ansari & Kenneth M. Ganga
//

#ifndef __HEALPIX__
#define __HEALPIX__

// MARK: HEALPix functions
/* ctab[m] = (short)(
       (m&0x1 )       | ((m&0x2 ) << 7) | ((m&0x4 ) >> 1) | ((m&0x8 ) << 6)
    | ((m&0x10) >> 2) | ((m&0x20) << 5) | ((m&0x40) >> 3) | ((m&0x80) << 4)); */
constant const short ctab[]={
#define Z(a) a,a+1,a+256,a+257
#define Y(a) Z(a),Z(a+2),Z(a+512),Z(a+514)
#define X(a) Y(a),Y(a+4),Y(a+1024),Y(a+1028)
X(0),X(8),X(2048),X(2056)
#undef X
#undef Y
#undef Z
};

/* utab[m] = (short)(
      (m&0x1 )       | ((m&0x2 ) << 1) | ((m&0x4 ) << 2) | ((m&0x8 ) << 3)
    | ((m&0x10) << 4) | ((m&0x20) << 5) | ((m&0x40) << 6) | ((m&0x80) << 7)); */
constant const short utab[]={
#define Z(a) 0x##a##0, 0x##a##1, 0x##a##4, 0x##a##5
#define Y(a) Z(a##0), Z(a##1), Z(a##4), Z(a##5)
#define X(a) Y(a##0), Y(a##1), Y(a##4), Y(a##5)
X(0),X(1),X(4),X(5)
#undef X
#undef Y
#undef Z
};

inline int xyf2nest(int nside, int3 i)
{
    return (i.z*nside*nside) + (utab[i.x&0xff] | (utab[i.x>>8]<<16) | (utab[i.y&0xff]<<1) | (utab[i.y>>8]<<17));
}

inline int3 nest2xyf(int nside, int pix)
{
    const int npface = nside*nside, mask = npface-1, p = pix & mask, q = p >> 1;
    const int xx = (p&0x5555) | ((p&0x55550000)>>15), x = ctab[xx&0xff] | (ctab[xx>>8]<<4);
    const int yy = (q&0x5555) | ((q&0x55550000)>>15), y = ctab[yy&0xff] | (ctab[yy>>8]<<4);
    
    return int3(x, y, pix/npface);
}

inline int3 xyz2xyf(int nside, float3 v)
{
    const int mask = nside-1;
    const float za = fabs(v.z), t = atan2(v.y,v.x)/halfpi, tt = select(t, t+4.0, t<0.0); /* in [0,4) */
    
    if (za <= 2.0/3.0) /* Equatorial region */
    {
        const float temp1 = nside*(0.5+tt), temp2 = nside*(v.z*0.75);
        const int jp = (int)(temp1-temp2), ifp = jp/nside; /* index of  ascending edge line */
        const int jm = (int)(temp1+temp2), ifm = jm/nside; /* index of descending edge line */
        const int face = select(select(ifm+8, ifp, ifp<ifm), ifp|4, ifp==ifm);
        
        return int3(jm & mask, nside - (jp & mask) - 1, face);
    }
    else /* polar region, za > 2/3 */
    {
        const int ntt = min((int)tt, 3);
        const float tp = tt-ntt, tmp = nside*sqrt(3*(1-za));
        const int jp = min((int)(tp*tmp), mask); /* increasing edge line index */
        const int jm = min((int)((1.0-tp)*tmp), mask); /* decreasing edge line index */
        
        return select(int3(jp, jm, ntt+8), int3(mask-jm, mask-jp, ntt), v.z>=0);
    }
}

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
    
    if (isnan(v)) { output.write(colors[2], gid.xy, gid.z); return; }
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
    
    output.write(select(powr(saturate(mixer*v), gamma), nan, any(isnan(v))), gid.xy, gid.z);
}

// MARK: accumulate covariance of 3-channel data
kernel void covariance(
    constant float *x                   [[ buffer(0) ]],
    constant float *y                   [[ buffer(1) ]],
    constant float *z                   [[ buffer(2) ]],
    device float3 *avg                  [[ buffer(3) ]],
    device float3x3 *cov                [[ buffer(4) ]],
    constant uint &npix                 [[ buffer(5) ]],
    uint tid                            [[ thread_position_in_grid ]],
    uint width                          [[ threads_per_grid ]]
) {
    // thread-local accumulators
    float3 A = 0.0; float3x3 C = float3x3(0.0, 0.0, 0.0);
    
    // accumulate all the pixels in this thread
    for (uint i = tid; i < npix; i += width) {
        const float3 v = float3(x[i],y[i],z[i]);
        
        A += v; C += float3x3(
            float3(v.x*v.x,v.y*v.x,v.z*v.x),
            float3(v.x*v.y,v.y*v.y,v.z*v.y),
            float3(v.x*v.z,v.y*v.z,v.z*v.z)
        );
    }
    
    // store to shared buffer
    avg[tid] = A; cov[tid] = C;
    
    // hierarchical reduce
    for (uint s = width/2; s > 0; s >>= 1) {
        threadgroup_barrier(mem_flags::mem_device);
        if (tid < s && tid+s < npix) { avg[tid] += avg[tid+s]; cov[tid] += cov[tid+s]; }
    }
}

#endif /* __HEALPIX__ */
