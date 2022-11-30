//
//  ranking.c
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-29.
//

#include "ranking.h"
#include "quadsort.h"

void index_map(const float *data, int *index, int npix) {
    for (int i = 0; i < npix; i++) { index[i] = i; }
    quadsort(index, npix, sizeof(int), data);
}

void rank_map(const int *index, float *ranked, int npix) {
    for (int i = 0; i < npix; i++) { ranked[index[i]] = i/(npix-1.0); }
}
