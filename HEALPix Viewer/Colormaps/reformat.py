#!/usr/bin/env python

# import libraries
import numpy as np

lut = np.loadtxt("../../../cmb-peaks/libs/colormaps/Planck_Parchment.rgb")

print("let xxx = [")

for x in lut:
	print(f"    SIMD4<Float>({x[0]}/255.0, {x[1]}/255.0, {x[2]}/255.0, 1.0),")

print("]")
