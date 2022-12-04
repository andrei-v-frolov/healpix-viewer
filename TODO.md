# HEALPix Viewer TODO

### Current Status (Build 004)

- pointwise function transforms implemented

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support
- data analysis features (functional map transforms, equalization, etc.)

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- `Open File...` should open a new window if none available
- option to drag the map with colorbar...

### Bug Fixes

- CMB convention is looking from INSIDE - option to flip the maps!
- modal NSOpenPanel and NSSavePanel are called within transaction
- export with magnification is broken?
- range on equalized map is not set...
