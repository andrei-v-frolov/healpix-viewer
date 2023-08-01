# HEALPix Viewer TODO

### Current Status (Build 009)

- context menus in navigation view implemented
- navigation map list can be rearranged on macOS 13+
- false color map support (e.g. RGB = 100,147,217GHz) + decorrelation
- color mixer modes: co-add, mix to specified white point, blend in okLab
- gamut mapping with ACES gamut compressor and Rec.2100 HLG curves
- color gradient generation in okLab implemented
- single face texture array per MapData, preallocate instead of lazy
- support for integer type maps added (like HITS count in Planck maps)
- BAD_DATA guard (replacing with NAN) fixed
- libcfitsio updated to 4.3.0
- random map generation implemented

### Compliance Issues

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Optimizations

- proxy map to improve percieved transform performance
- switch to indirect buffers?
- always allocate mipmaps?
- if out of VRAM, downsample on CPU?
- const arguments to all inline Metal functions?
- use Picker sections? do I really need Picker id?
- faster 3x3 SVD? e.g. port https://github.com/ericjang/svd3?
- render using any texture in MapView, generate previews in packground

### Feature Requests

- magnifier glass
- transparency mask?
- save and load view state (also maybe mixer state?)
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
- thumbnails do not update in mixer
- theta and phi swapped in healpix paper
- disable colorbar in false color map export
- @MainActor broke thumbnail generation
- fix focus state handling in ColorList...
