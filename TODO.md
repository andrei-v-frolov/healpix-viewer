# HEALPix Viewer TODO

### Current Status (Build 008)

- proper Settings window added
- selectable annotation font and color
- Python difference (RWB) colormap added
- power law and exponential transforms added
- export as GIF, PNG, HEIF, and 16-bit TIFF format
- more realistic lighting (Lambert reflection, gamma corrected)
- code refactored to encapsulate view parameters into a struct
- keep, copy, and paste viewer setting sets between loaded maps
- antialiasing of very large maps (i.e. LOD pyramid in MapView)
- selectable color texture precision (i.e. memory footprint)
- (optional) map thumbnails added to navigation panel

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- magnifier glass
- selectable GPU device (e.g. discrete/external unit)
- option to drag the map with colorbar...
- false color map support (e.g. RGB = 100,147,217GHz channels)
- proxy map to improve percieved transform performance
- command line interface

### Long Term Targets

- proper support of other coordinate systems (equatorial and ecliptic)
- integrate with PLA/LAMBDA for data loading?
- integrate with CADC database for object lookup?

### Bug Fixes

- `Open File...` should open a new window if none available
- modal NSOpenPanel and NSSavePanel are called within transaction
- display alert if FITS format is not HEALPix (or unsupported scheme)
- fix crash on out-of-memory, display alert and refuse to load instead
- map thumbnail flashes (transform buffer overwritten in-flight)...
- RangeView got broken somehow...
