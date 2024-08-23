//
//  ranking.h
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-29.
//

#ifndef ranking_h
#define ranking_h

void index_map(const float *data, const int npix, int *index, int *nobs);
void rank_map(const float *data, const int *index, const int nobs, float *ranked);

#endif /* ranking_h */
