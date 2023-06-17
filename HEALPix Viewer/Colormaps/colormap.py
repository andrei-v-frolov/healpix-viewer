#!/usr/bin/env python

import matplotlib
import numpy as np

gradient = ["blue", "white", "red"]
colormap = matplotlib.colors.LinearSegmentedColormap.from_list("difference", gradient)

print("let xxx = [")

for x in np.linspace(0.0,1.0,256):
	(r,g,b,a) = colormap(x)
	print(f"    SIMD4<Float>({r}, {g}, {b}, {a}),")

print("]")