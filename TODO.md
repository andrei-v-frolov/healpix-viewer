# HEALPix Viewer TODO

### Current Status (Build 009)

- build number bumped

### Compliance Issues

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- false color map support (e.g. RGB = 100,147,217GHz + gamma)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Optimizations

- proxy map to improve percieved transform performance
- switch to indirect buffers?
- preallocate instead of lazy...

### Feature Requests

- magnifier glass
- save and load view state
- view from inside should be part of projection settings?
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
- file load always crashes on external/discrete GPU
- animation is disabled on cold start
