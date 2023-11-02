# HEALPix Viewer TODO

### Current Status (Build 009)

- stereographic projection added
- lime colormap added to complement HEALPix hot and cold schemes
- more Python colormaps added (viridis, spectral, seismic, RdBu)
- text in info overlays can be selected & copied
- navigation map list can be rearranged on macOS 13+
- context menus in navigation view and color bar implemented
- false color map support (e.g. RGB = 100,147,217GHz) + decorrelation
- color mixer modes: co-add, mix to specified white point, blend in okLab
- gamut mapping with ACES gamut compressor and filmic S-curves
- color gradient generation (via blending in okLab) implemented
- single face texture array per MapData, preallocate instead of lazy
- support for integer type maps added (like HITS count in Planck maps)
- BAD_DATA guard (replacing with NaN) fixed
- random map generation implemented (using Random123)
- libcfitsio updated to 4.3.0

### Compliance Issues

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

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

- render in HDR, output to HEIF10 and OpenEXR
- parameter and spatial correlation priors in component separator
- magnifier glass
- transparency mask?
- free rotation mode?
- save and load view state (also maybe mixer state?)
- view from inside should be part of projection settings?
- make compress gamut into global setting?
- command line interface (via ArgumentParser)
- make figure of space filling pixel order curves!
- make okLab gamut plot
- pigment mixing (https://scrtwpns.com/mixbox/docs)?

### Future Targets

- proper support of other coordinate systems (equatorial and ecliptic)
- integrate with PLA/LAMBDA for data loading?
- integrate with CADC database for object lookup?

### Bug Fixes

- reallocate texture in MapData if settings change?
- button size changed in Export As dialog!?
- modal NSOpenPanel and NSSavePanel are called within transaction
- display alert if FITS format is not HEALPix (or unsupported scheme)
- fix crash on out-of-memory, display alert and refuse to load instead
- adjust LOD level for different projections
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
- chromaticity diagram for color mixer annotation?
- polarization angle + hue colormap?
