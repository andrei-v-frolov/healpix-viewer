//
//  rawmap.h
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-16.
//

#ifndef rawmap_h
#define rawmap_h

#define BAD_DATA -1.6375000E+30F

// full-sky conversion primitives, single precision float
void raw2map_frp(const float *in, float *out, long nside, double *min, double *max);
void raw2map_frn(const float *in, float *out, long nside, double *min, double *max);
void raw2map_fnp(const float *in, float *out, long nside, double *min, double *max);
void raw2map_fnn(const float *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, double precision float
void raw2map_drp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_drn(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dnp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dnn(const double *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, signed 16-bit integer
void raw2map_srp(const short *in, float *out, long nside, double *min, double *max);
void raw2map_srn(const short *in, float *out, long nside, double *min, double *max);
void raw2map_snp(const short *in, float *out, long nside, double *min, double *max);
void raw2map_snn(const short *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, signed 32-bit integer
void raw2map_irp(const int *in, float *out, long nside, double *min, double *max);
void raw2map_irn(const int *in, float *out, long nside, double *min, double *max);
void raw2map_inp(const int *in, float *out, long nside, double *min, double *max);
void raw2map_inn(const int *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, signed 64-bit integer
void raw2map_lrp(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_lrn(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_lnp(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_lnn(const long long *in, float *out, long nside, double *min, double *max);

#endif /* rawmap_h */
