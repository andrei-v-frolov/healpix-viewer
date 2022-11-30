//
//  ranking.h
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-29.
//

#ifndef ranking_h
#define ranking_h

void index_map(const float *data, int *index, int npix);
void rank_map(const int *index, float *ranked, int npix);

#endif /* ranking_h */
