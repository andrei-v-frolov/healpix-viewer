//
//  rawmap.h
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-16.
//

#ifndef rawmap_h
#define rawmap_h

#define BAD_DATA -1.6375000E+30F

// full-sky conversion primitives
void raw2map_ffrp(const float *in, float *out, long nside, double *min, double *max);
void raw2map_ffrn(const float *in, float *out, long nside, double *min, double *max);
void raw2map_ffnp(const float *in, float *out, long nside, double *min, double *max);
void raw2map_ffnn(const float *in, float *out, long nside, double *min, double *max);

void raw2map_fdrp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_fdrn(const double *in, float *out, long nside, double *min, double *max);
void raw2map_fdnp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_fdnn(const double *in, float *out, long nside, double *min, double *max);

#endif /* rawmap_h */
