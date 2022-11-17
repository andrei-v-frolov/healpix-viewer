//
//  rawmap.c
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-16.
//

// low-level backends to bring the HEALPix map into canonical form
// (namely NESTED float single-precision data suitable for GPU and Metal)
// naming convention goes according to raw2map_????, with four letters corresponding to
//   f = full sky, j = partial sky (long index), k = partial sky (int index)
//   f = float data, d = double data
//   r = 'RING' ordering, n = 'NESTED' ordering
//   p = no sign flip, n = sign flip (for IAU polarization convention)

#include <float.h>
#include "rawmap.h"
#include "../../cfitsio/healpix/chealpix.h"

// full-sky float buffer in RING ordering, no sign flip
void raw2map_ffrp(const float *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        long p; nest2ring(nside, i, &p); float v = in[p];
        if (v == BAD_DATA) { out[i] = nan; continue; }
        
        out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky float buffer in RING ordering, sign flip
void raw2map_ffrn(const float *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        long p; nest2ring(nside, i, &p); float v = in[p];
        if (v == BAD_DATA) { out[i] = nan; continue; }
        
        v = -v; out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky float buffer in NESTED ordering, no sign flip
void raw2map_ffnp(const float *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        float v = in[i]; if (v == BAD_DATA) { out[i] = nan; continue; }
        
        out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky float buffer in NESTED ordering, sign flip
void raw2map_ffnn(const float *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        float v = in[i]; if (v == BAD_DATA) { out[i] = nan; continue; }
        
        v = -v; out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky double buffer in RING ordering, no sign flip
void raw2map_fdrp(const double *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        long p; nest2ring(nside, i, &p); float v = in[p];
        if (v == BAD_DATA) { out[i] = nan; continue; }
        
        out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky double buffer in RING ordering, sign flip
void raw2map_fdrn(const double *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        long p; nest2ring(nside, i, &p); float v = in[p];
        if (v == BAD_DATA) { out[i] = nan; continue; }
        
        v = -v; out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky double buffer in NESTED ordering, no sign flip
void raw2map_fdnp(const double *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        float v = in[i]; if (v == BAD_DATA) { out[i] = nan; continue; }
        
        out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}

// full-sky double buffer in NESTED ordering, sign flip
void raw2map_fdnn(const double *in, float *out, long nside, double *min, double *max) {
    float minval = FLT_MAX, maxval = -FLT_MAX, nan = 1.0/0.0;
    
    for (long i = 0; i < 12*nside*nside; i++) {
        float v = in[i]; if (v == BAD_DATA) { out[i] = nan; continue; }
        
        v = -v; out[i] = v;
        
        if (v < minval) { minval = v; }
        if (v > maxval) { maxval = v; }
    }
    
    *min = minval;
    *max = maxval;
}
