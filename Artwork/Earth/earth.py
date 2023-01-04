#!/usr/bin/env python

#######################################################################
# import libraries
#######################################################################

import numpy as np
import healpy as hp
from skimage.io import imread

#######################################################################
# import Earth DEM tiles; full dataset uses 6x4 tiling @ 15" resolution
# data downloaded from http://www.viewfinderpanoramas.org/dem3.html)
#######################################################################

nx = 14401
ny = 10801

# polar coordinates grid covering entire dataset
theta = np.linspace(0, np.pi, num=4*ny)[:,None]
phi = np.linspace(-np.pi, np.pi, num=6*nx)

# output map (at downsampled resolution)
nside = 4*2048; npix = hp.nside2npix(nside)
map = np.zeros(npix); w = np.zeros(npix)

# load up tiles
for j in range(4):
	for i in range(6):
		tile = chr(ord('A')+i+6*j)
		image = imread(f'tiles/15-{tile}.tif')
		assert image.shape == (ny,nx), "Unexpected tile shape..."
		print("Sampling tile " + tile)

		pix = hp.ang2pix(nside, theta[j*ny:(j+1)*ny], phi[i*nx:(i+1)*nx], nest=True)
		map[pix] += image; w[pix] += 1.0

# average elevation data
map /= w

# output HEALPix map (in NESTED order, double precision)
hp.fitsfunc.write_map(f'earth-{nside}.fits', map, nest=True, dtype=np.float32, overwrite=True)

#######################################################################
# plot map data
#######################################################################

import matplotlib.pyplot as plt

hp.mollview(map, nest=True, cmap="gray", xsize=2000, flip="geo")

plt.show()
