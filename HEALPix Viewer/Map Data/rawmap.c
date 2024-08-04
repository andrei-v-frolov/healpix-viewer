//
//  rawmap.c
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-16.
//

#include <math.h>
#include <float.h>
#include "rawmap.h"
#include "../../cfitsio/healpix/chealpix.h"

// low-level backends to bring the HEALPix map into canonical form,
// namely NESTED float single-precision data suitable for GPU and Metal
// fullsky primitives are named raw2map_???, with three letters corresponding to
//   f = float data, d = double data, s = 16-bit int, i = 32-bit int, l/x = 64-bit int
//   r = 'RING' ordering, n = 'NESTED' ordering
//   p = no sign flip, n = sign flip (for IAU polarization convention)

// MARK: full-sky conversion primitives, single precision float
#define RAW_RP void raw2map_frp(const float *in, float *out, long nside, double *min, double *max)
#define RAW_RN void raw2map_frn(const float *in, float *out, long nside, double *min, double *max)
#define RAW_NP void raw2map_fnp(const float *in, float *out, long nside, double *min, double *max)
#define RAW_NN void raw2map_fnn(const float *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_RP
#undef RAW_RN
#undef RAW_NP
#undef RAW_NN

// MARK: full-sky conversion primitives, double precision float
#define RAW_RP void raw2map_drp(const double *in, float *out, long nside, double *min, double *max)
#define RAW_RN void raw2map_drn(const double *in, float *out, long nside, double *min, double *max)
#define RAW_NP void raw2map_dnp(const double *in, float *out, long nside, double *min, double *max)
#define RAW_NN void raw2map_dnn(const double *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_RP
#undef RAW_RN
#undef RAW_NP
#undef RAW_NN

// MARK: full-sky conversion primitives, signed 16-bit integer
#define RAW_RP void raw2map_srp(const short *in, float *out, long nside, double *min, double *max)
#define RAW_RN void raw2map_srn(const short *in, float *out, long nside, double *min, double *max)
#define RAW_NP void raw2map_snp(const short *in, float *out, long nside, double *min, double *max)
#define RAW_NN void raw2map_snn(const short *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_RP
#undef RAW_RN
#undef RAW_NP
#undef RAW_NN

// MARK: full-sky conversion primitives, signed 32-bit integer
#define RAW_RP void raw2map_irp(const int *in, float *out, long nside, double *min, double *max)
#define RAW_RN void raw2map_irn(const int *in, float *out, long nside, double *min, double *max)
#define RAW_NP void raw2map_inp(const int *in, float *out, long nside, double *min, double *max)
#define RAW_NN void raw2map_inn(const int *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_RP
#undef RAW_RN
#undef RAW_NP
#undef RAW_NN

// MARK: full-sky conversion primitives, signed 64-bit integer
#define RAW_RP void raw2map_lrp(const long *in, float *out, long nside, double *min, double *max)
#define RAW_RN void raw2map_lrn(const long *in, float *out, long nside, double *min, double *max)
#define RAW_NP void raw2map_lnp(const long *in, float *out, long nside, double *min, double *max)
#define RAW_NN void raw2map_lnn(const long *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_RP
#undef RAW_RN
#undef RAW_NP
#undef RAW_NN

// MARK: full-sky conversion primitives, signed 64-bit integer
#define RAW_RP void raw2map_xrp(const long long *in, float *out, long nside, double *min, double *max)
#define RAW_RN void raw2map_xrn(const long long *in, float *out, long nside, double *min, double *max)
#define RAW_NP void raw2map_xnp(const long long *in, float *out, long nside, double *min, double *max)
#define RAW_NN void raw2map_xnn(const long long *in, float *out, long nside, double *min, double *max)
#include "rawmap.tmpl"
#undef RAW_RP
#undef RAW_RN
#undef RAW_NP
#undef RAW_NN
