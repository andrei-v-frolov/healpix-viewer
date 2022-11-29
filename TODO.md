# HEALPix Viewer TODO

### Current Status (Build 004)

- started work on data transforms...

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support
- data analysis features (functional map transforms, equalization, etc.)

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Bug Fixes

- CMB convention is looking from INSIDE - option to flip the maps!
- modal NSOpenPanel and NSSavePanel are called within transaction
- release UnsafeMutableBuffers backing maps in HpXFile on deinitialization
- check if recoloring is triggered twice on (transformed) map loading
