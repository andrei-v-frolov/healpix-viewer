# HEALPix Viewer TODO

### Current Status (Build 009)

- equidistant, stereographic and Aitoff projections added
- lime colormap added to complement HEALPix hot and cold schemes
- more Python colormaps added (viridis, spectral, seismic, RdBu)
- render in HDR, output to 16-bit float OpenEXR (on macOS 14+)
- text in info overlays can be selected & copied
- navigation map list can be rearranged on macOS 13+
- context menus in navigation view and color bar implemented
- false color map support (e.g. RGB = 100,147,217GHz) + decorrelation
- color mixer modes: co-add, mix to specified white point, blend in okLab
- gamut mapping with ACES gamut compressor and filmic S-curves
- chromaticity diagram for color mixer showing color cube gamut
- custom gradient generation (via blending in okLab) implemented
- animated zebra pattern for out of SDR gamut gradient colors
- single face texture array per MapData, preallocate instead of lazy
- support for integer type maps added (like HITS count in Planck maps)
- support for indexed partial sky maps added (like SPIDER and BOOMERanG)
- BAD_DATA guard (replacing with NaN) fixed, ignored in statistics
- random map generation implemented (using Random123)
- CFITSIO updated to 4.4.1, zlib updated to 1.3.1

### Planned Features

- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Optimizations

- move export from map state to preferences
- factor out modified anchors in gradient
- proxy map to improve percieved transform performance
- switch to indirect buffers?
- always allocate mipmaps?
- conform to Transferable?
- if out of VRAM, downsample on CPU?
- [weak self] reference in async closures?
- const arguments to all inline Metal functions?
- use Picker sections? do I really need Picker id?
- faster 3x3 SVD? e.g. port https://github.com/ericjang/svd3?
- render using any texture in MapView, generate previews in background

### Feature Requests

- parameter and spatial correlation priors in component separator
- magnifier glass
- transparency mask?
- free rotation mode?
- save and load view state (also maybe mixer state?)
- view from inside should be part of projection settings?
- make compress gamut into global setting?
- command line interface (via ArgumentParser)
- make figure of space filling pixel order curves!
- pigment mixing (https://scrtwpns.com/mixbox/docs)?

### Future Targets

- proper support of other coordinate systems (equatorial and ecliptic)
- integrate with PLA/LAMBDA for data loading?
- integrate with CADC database for object lookup?

### Bug Fixes

- reallocate texture in MapData if settings change?
- button size changed in Export As dialog!?
- display alert if FITS format is not HEALPix (or unsupported scheme)
- fix crash on out-of-memory, display alert and refuse to load instead
- fallback for JSON parsers
- RangeView got broken somehow...
- file load always crashes on external/discrete GPU
- thumbnails do not update in mixer (and update after done)
- disable colorbar in false color map export
- fix focus state handling in ColorList...
- map range get trashed when switching from component map
- find the cause of lag in ComponentView (also related leak)
- fix sampling of PDF tails in statistics overlay
- FontPopUp update broke default selection?

### Needs Testing

- check that Intel GPU textures are little-endian
- check default CAMetalLayer backing format on Intel

### Random ideas
- link to libsharp for CPU FFTs? but where are the docs?
- polarization angle + hue colormap?
