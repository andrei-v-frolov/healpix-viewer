### Version 1.1 Beta (Build 008)

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

### Version 1.0 (Build 007)

- **first public release**
- action of `Cursor Readout` menu item fixed

### Version 1.0 (Build 006)

- cursor readout (latitude, longitude, pixel number & map value)
- gesture support for magnification and rotation (azimuth) added
- right click centers along geodesic, option to keep azimuth locked
- swipes spin sphere around, recentering to original location

### Version 1.0 (Build 005)

- center map projection on location of a right click of a mouse
- Hammer and equirectangular (aka cylindrical) projections added
- longitude and latitude parametrization fixed

### Version 1.0 (Build 004)

- background map analysis implemented
- pointwise function transforms implemented
- equalization and normalization implemented
- statistical analysis overlay is implemented (macOS 13 only)
- Drag and Drop of charts as PDF is implemented (no transparency)
- option to flip the view from inside & outside of celestial sphere added
- CFITSIO updated to version 4.2.0

### Version 1.0 (Build 003)

- export crash on Intel GPU fixed

### Version 1.0 (Build 002)

- `File Open` is implemented
- `Export As` is implemented
- Drag and Drop support is implemented
- saving textures as PNG is implemented
- text annotations render to bitmap image
- oversampling using Lanczos algorithm

### Version 1.0 (Build 001)

- initial release for public testing
- all major pieces in place, UI still not there
- Metal rendering of HEALPix sphere implemented
- HEALPix full-sky file format support implemented
- data analysis (CDF ranking in particular) not done
