//
//  ranking.c
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-29.
//

#include <math.h>
#include <float.h>
#include "ranking.h"
#include "quadsort.h"

// build index of regular map values
void index_map(const float *data, const int npix, int *index, int *nobs) {
    register int k = 0; for (int i = 0; i < npix; i++) { if (isfinite(data[i])) { index[k] = i; k++; } }
    *nobs = k; quadsort(index, *nobs, sizeof(int), data);
}

// rank unique map values (i.e. equalize map)
void rank_map(const float *data, const int *index, const int nobs, float *ranked) {
    register float v = NAN;
    for (int i = 0, j = 0; i < nobs; i++) {
        const register int k = index[i];
        const register float u = data[k];
        if (u != v) { v = u; j = i; }
        ranked[k] = (j+0.5)/nobs;
    }
}
