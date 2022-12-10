# HEALPix Viewer TODO

### Current Status (Build 004)

- background map analysis implemented
- pointwise function transforms implemented
- equalization and normalization implemented
- statistical analysis overlay is implemented
- Drag and Drop of charts as PDF is implemented

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- option to drag the map with colorbar...

### Bug Fixes

- `Open File...` should open a new window if none available
- CMB convention is looking from INSIDE - option to flip the maps!
- modal NSOpenPanel and NSSavePanel are called within transaction
- export with magnification is broken? confirmed .n tag in render()
