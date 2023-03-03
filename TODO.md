# HEALPix Viewer TODO

### Current Status (Build 006)

- cursor readout (latitude, longitude, pixel number & map value)

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- magnifier glass
- option to drag the map with colorbar...
- false color map support (e.g. RGB = 100,147,217GHz channels)
- antialiasing of very large maps (i.e. LOD pyramid in MapView)
- command line interface

### Bug Fixes

- `Open File...` should open a new window if none available
- modal NSOpenPanel and NSSavePanel are called within transaction
- gesture support seems to be broken? retest and confirm later...
- default orientation setting gets ignored in new window
