//
//  rawmap.c
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-16.
//

// low-level backends to bring the HEALPix map into canonical form
// (namely NESTED float single-precision data suitable for GPU and Metal)
// naming convention goes according to raw2map_????, with four letters corresponding to
//   f = float data, d = double data, s = 16-bit int, i = 32-bit int, l = 64-bit int
//   f = full sky, j = partial sky (long index), k = partial sky (int index)
//   r = 'RING' ordering, n = 'NESTED' ordering
//   p = no sign flip, n = sign flip (for IAU polarization convention)

#include <math.h>
#include <float.h>
#include "rawmap.h"
#include "../../cfitsio/healpix/chealpix.h"

// MARK: full-sky conversion primitives, single precision float
#define RAW_FRP void raw2map_ffrp(const float *in, float *out, long nside, double *min, double *max)
#define RAW_FRN void raw2map_ffrn(const float *in, float *out, long nside, double *min, double *max)
#define RAW_FNP void raw2map_ffnp(const float *in, float *out, long nside, double *min, double *max)
#define RAW_FNN void raw2map_ffnn(const float *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_FRP
#undef RAW_FRN
#undef RAW_FNP
#undef RAW_FNN

// MARK: full-sky conversion primitives, double precision float
#define RAW_FRP void raw2map_dfrp(const double *in, float *out, long nside, double *min, double *max)
#define RAW_FRN void raw2map_dfrn(const double *in, float *out, long nside, double *min, double *max)
#define RAW_FNP void raw2map_dfnp(const double *in, float *out, long nside, double *min, double *max)
#define RAW_FNN void raw2map_dfnn(const double *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_FRP
#undef RAW_FRN
#undef RAW_FNP
#undef RAW_FNN

// MARK: full-sky conversion primitives, signed 16-bit integer
#define RAW_FRP void raw2map_sfrp(const short *in, float *out, long nside, double *min, double *max)
#define RAW_FRN void raw2map_sfrn(const short *in, float *out, long nside, double *min, double *max)
#define RAW_FNP void raw2map_sfnp(const short *in, float *out, long nside, double *min, double *max)
#define RAW_FNN void raw2map_sfnn(const short *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_FRP
#undef RAW_FRN
#undef RAW_FNP
#undef RAW_FNN

// MARK: full-sky conversion primitives, signed 32-bit integer
#define RAW_FRP void raw2map_ifrp(const int *in, float *out, long nside, double *min, double *max)
#define RAW_FRN void raw2map_ifrn(const int *in, float *out, long nside, double *min, double *max)
#define RAW_FNP void raw2map_ifnp(const int *in, float *out, long nside, double *min, double *max)
#define RAW_FNN void raw2map_ifnn(const int *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_FRP
#undef RAW_FRN
#undef RAW_FNP
#undef RAW_FNN

// MARK: full-sky conversion primitives, signed 64-bit integer
#define RAW_FRP void raw2map_lfrp(const long long *in, float *out, long nside, double *min, double *max)
#define RAW_FRN void raw2map_lfrn(const long long *in, float *out, long nside, double *min, double *max)
#define RAW_FNP void raw2map_lfnp(const long long *in, float *out, long nside, double *min, double *max)
#define RAW_FNN void raw2map_lfnn(const long long *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_FRP
#undef RAW_FRN
#undef RAW_FNP
#undef RAW_FNN
