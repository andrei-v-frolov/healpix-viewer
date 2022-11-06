//
//  Healpix.metal
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-10-21.
//

#ifndef __HEALPIX__
#define __HEALPIX__

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

inline int xyf2nest (int nside, int ix, int iy, int face)
{
    return (face*nside*nside) + (utab[ix&0xff] | (utab[ix>>8]<<16) | (utab[iy&0xff]<<1) | (utab[iy>>8]<<17));
}

inline int3 nest2xyf (int nside, int pix)
{
    const int npface = nside*nside, mask = npface-1;
    const int p = pix & mask, q = p >> 1;
    
    const int xx = (p&0x5555) | ((p&0x55550000)>>15);
    const int x = ctab[xx&0xff] | (ctab[xx>>8]<<4);
    
    const int yy = (q&0x5555) | ((q&0x55550000)>>15);
    const int y = ctab[yy&0xff] | (ctab[yy>>8]<<4);
    
    return int3(x,y,pix/npface);
}

#endif /* __HEALPIX__ */
