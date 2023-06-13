# HEALPix Viewer TODO

### Current Status (Build 008)

- build bumped to 008

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- magnifier glass
- selectable annotation font
- option to drag the map with colorbar...
- copy and paste setting sets between loaded maps
- keep colorbar and transform settings for each loaded map
- false color map support (e.g. RGB = 100,147,217GHz channels)
- antialiasing of very large maps (i.e. LOD pyramid in MapView)
- command line interface

### Long Term Targets

- proper support of other coordinate systems (equatorial and ecliptic)
- integrate with PLA/LAMBDA for data loading?
- integrate with CADC database for object lookup?

### Bug Fixes

- `Open File...` should open a new window if none available
- modal NSOpenPanel and NSSavePanel are called within transaction
- display alert if FITS format is not HEALPix (or unsopported scheme)
- fix crash on out-of-memory, display alert and refuse to load instead
