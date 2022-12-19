# HEALPix Viewer TODO

### Current Status (Build 004)

- background map analysis implemented
- pointwise function transforms implemented
- equalization and normalization implemented
- statistical analysis overlay is implemented (macOS 13 only)
- Drag and Drop of charts as PDF is implemented (no transparency)
- option to flip the view from inside & outside of celestial sphere added

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
- export with magnification is broken? confirmed .n tag in render()
- set range results in blanck PDF chart - this is a bug in Charts trying
  to allocate texture for entire data range & exceeding Metal size limits
