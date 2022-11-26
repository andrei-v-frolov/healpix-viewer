# HEALPix Viewer TODO

### Current Status (Build 002)

- `File Open` is implemented
- `Export As` is implemented
- Drag and Drop support is implemented
- saving textures as PNG is implemented
- text annotations render to bitmap image
- oversampling using Lanczos algorithm

### Public Release Blocking

- partial sky (`INDXSCHM = 'EXPLICIT'`) HEALPix file support
- data analysis features (functional map transforms, equalization, etc.)

### Planned Features

- better automatic range finder (max entropy, limit statistics?)
- line convolution for polarization and vector maps
- arithmetic operations on loaded map data (ala fcalc)

### Bug Fixes

- modal NSOpenPanel and NSSavePanel are called within transaction
