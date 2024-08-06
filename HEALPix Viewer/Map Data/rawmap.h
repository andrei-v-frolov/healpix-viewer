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
void idx2map_fp(const long *idx, const float *in, float *out, long nobs, double *min, double *max);
void idx2map_fn(const long *idx, const float *in, float *out, long nobs, double *min, double *max);

// full-sky conversion primitives, double precision float
void raw2map_drp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_drn(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dnp(const double *in, float *out, long nside, double *min, double *max);
void raw2map_dnn(const double *in, float *out, long nside, double *min, double *max);
void idx2map_dp(const long *idx, const double *in, float *out, long nobs, double *min, double *max);
void idx2map_dn(const long *idx, const double *in, float *out, long nobs, double *min, double *max);

// full-sky conversion primitives, signed 16-bit integer
void raw2map_srp(const short *in, float *out, long nside, double *min, double *max);
void raw2map_srn(const short *in, float *out, long nside, double *min, double *max);
void raw2map_snp(const short *in, float *out, long nside, double *min, double *max);
void raw2map_snn(const short *in, float *out, long nside, double *min, double *max);
void idx2map_sp(const long *idx, const short *in, float *out, long nobs, double *min, double *max);
void idx2map_sn(const long *idx, const short *in, float *out, long nobs, double *min, double *max);
long reindex_sr(const short *in, long *idx, long nobs, long nside);
long reindex_sn(const short *in, long *idx, long nobs, long nside);

// full-sky conversion primitives, signed 32-bit integer
void raw2map_irp(const int *in, float *out, long nside, double *min, double *max);
void raw2map_irn(const int *in, float *out, long nside, double *min, double *max);
void raw2map_inp(const int *in, float *out, long nside, double *min, double *max);
void raw2map_inn(const int *in, float *out, long nside, double *min, double *max);
void idx2map_ip(const long *idx, const int *in, float *out, long nobs, double *min, double *max);
void idx2map_in(const long *idx, const int *in, float *out, long nobs, double *min, double *max);
long reindex_ir(const int *in, long *idx, long nobs, long nside);
long reindex_in(const int *in, long *idx, long nobs, long nside);

// full-sky conversion primitives, signed 64-bit integer
void raw2map_lrp(const long *in, float *out, long nside, double *min, double *max);
void raw2map_lrn(const long *in, float *out, long nside, double *min, double *max);
void raw2map_lnp(const long *in, float *out, long nside, double *min, double *max);
void raw2map_lnn(const long *in, float *out, long nside, double *min, double *max);
void idx2map_lp(const long *idx, const long *in, float *out, long nobs, double *min, double *max);
void idx2map_ln(const long *idx, const long *in, float *out, long nobs, double *min, double *max);
long reindex_lr(const long *in, long *idx, long nobs, long nside);
long reindex_ln(const long *in, long *idx, long nobs, long nside);

// full-sky conversion primitives, signed 64-bit integer
void raw2map_xrp(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_xrn(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_xnp(const long long *in, float *out, long nside, double *min, double *max);
void raw2map_xnn(const long long *in, float *out, long nside, double *min, double *max);
void idx2map_xp(const long *idx, const long long *in, float *out, long nobs, double *min, double *max);
void idx2map_xn(const long *idx, const long long *in, float *out, long nobs, double *min, double *max);
long reindex_xr(const long long *in, long *idx, long nobs, long nside);
long reindex_xn(const long long *in, long *idx, long nobs, long nside);

#endif /* rawmap_h */
