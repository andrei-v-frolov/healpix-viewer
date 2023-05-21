# HEALPix Viewer TODO

### Current Status (Build 007)

- **first public release**
- action of `Cursor Readout` menu item fixed

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support

### Planned Features

- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Feature Requests

- magnifier glass
- selectable annotation font
- option to drag the map with colorbar...
- false color map support (e.g. RGB = 100,147,217GHz channels)
- antialiasing of very large maps (i.e. LOD pyramid in MapView)
- command line interface

### Bug Fixes

- `Open File...` should open a new window if none available
- modal NSOpenPanel and NSSavePanel are called within transaction
