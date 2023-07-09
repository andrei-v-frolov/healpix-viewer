# HEALPix Viewer TODO

### Current Status (Build 008)

- proper Settings window added
- selectable annotation font and color
- Python difference (RWB) colormap added
- power law and exponential transforms added
- export and drag as GIF, PNG, HEIF, and 16-bit TIFF format
- more realistic lighting (Lambert reflection, gamma corrected)
- code refactored to encapsulate view parameters into a struct
- keep, copy, and paste viewer setting sets between loaded maps
- antialiasing of very large maps (i.e. LOD pyramid in MapView)
- selectable color texture precision (i.e. memory footprint)
- selectable GPU device (e.g. discrete/external unit)
- (optional) map thumbnails added to navigation panel

### Compliance Issues

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- false color map support (e.g. RGB = 100,147,217GHz) + gamma
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Optimizations

- proxy map to improve percieved transform performance
- switch to indirect buffers?
- preallocate instead of lazy...

### Feature Requests

- magnifier glass
- view from inside should be part of projection settings?
- save and load view state
- command line interface (via ArgumentParser)

### Future Targets

- proper support of other coordinate systems (equatorial and ecliptic)
- integrate with PLA/LAMBDA for data loading?
- integrate with CADC database for object lookup?

### Bug Fixes

- modal NSOpenPanel and NSSavePanel are called within transaction
- display alert if FITS format is not HEALPix (or unsupported scheme)
- fix crash on out-of-memory, display alert and refuse to load instead
- adjust LOD level for different projections
- fallback for JSON parsers
- RangeView got broken somehow...
