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
void raw2map_ffrp(const float *in, float *out, long nside, double *min, double *max);
void raw2map_ffrn(const float *in, float *out, long nside, double *min, double *max);
void raw2map_ffnp(const float *in, float *out, long nside, double *min, double *max);
void raw2map_ffnn(const float *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, double precision float
void raw2map_dfrp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dfrn(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dfnp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dfnn(const double *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, signed 16-bit integer
void raw2map_sfrp(const short *in, float *out, long nside, double *min, double *max);
void raw2map_sfrn(const short *in, float *out, long nside, double *min, double *max);
void raw2map_sfnp(const short *in, float *out, long nside, double *min, double *max);
void raw2map_sfnn(const short *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, signed 32-bit integer
void raw2map_ifrp(const int *in, float *out, long nside, double *min, double *max);
void raw2map_ifrn(const int *in, float *out, long nside, double *min, double *max);
void raw2map_ifnp(const int *in, float *out, long nside, double *min, double *max);
void raw2map_ifnn(const int *in, float *out, long nside, double *min, double *max);

// full-sky conversion primitives, signed 64-bit integer
void raw2map_lfrp(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_lfrn(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_lfnp(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_lfnn(const long long *in, float *out, long nside, double *min, double *max);

#endif /* rawmap_h */
