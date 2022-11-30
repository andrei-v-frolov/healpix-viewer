//
//  ranking.c
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-29.
//

#include "ranking.h"
#include "quadsort.h"

float *map;

int compare(const int *a, const int *b) {
    return map[*a] > map[*b];
}

void index_map(const float *data, int *index, int npix) {
    map = data;
    for (int i = 0; i < npix; i++) { index[i] = i; }
    quadsort(index, npix, sizeof(int), compare);
}

void rank_map(const int *index, float *ranked, int npix) {
    for (int i = 0; i < npix; i++) { ranked[index[i]] = i/(npix-1.0); }
}
