# HEALPix Viewer TODO

### Current Status (Build 005)

- Hammer and equirectangular (aka cylindrical) projections added
- longitude and latitude parametrization fixed

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- option to drag the map with colorbar...
- cursor readout (latitude, longitude & map value) and magnifier
- false color map support (e.g. RGB = 100,147,217GHz channels)
- antialiasing of very large maps (i.e. LOD pyramid in MapView)
- command line interface

### Bug Fixes

- `Open File...` should open a new window if none available
- modal NSOpenPanel and NSSavePanel are called within transaction
- gesture support seems to be broken? retest and confirm later...
