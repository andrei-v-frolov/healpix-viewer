# HEALPix Viewer TODO

### Current Status (Build 005)

- longitude and latitude parametrization fixed (hopefully once and for all now)!

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
- modal NSOpenPanel and NSSavePanel are called within transaction
