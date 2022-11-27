# HEALPix Viewer TODO

### Current Status (Build 003)

- export crash on Intel GPU fixed

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support
- data analysis features (functional map transforms, equalization, etc.)

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Bug Fixes

- modal NSOpenPanel and NSSavePanel are called within transaction
