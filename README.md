# healpix-viewer
HEALPix data viewer for macOS.

HEALPix [[Gorski et. al.](https://healpix.jpl.nasa.gov)] is a de-facto standard for CMB data storage and analysis, and is widely used for current and upcoming experiments. Almost all the data sets in [Lambda](https://lambda.gsfc.nasa.gov) use HEALPix. As much as I like `map2gif` (which is included in HEALPix distribution) for scripting, I wanted an interactive option to quickly tweak the maps, preferably with some GUI, and so I wrote it.

### Features:
- modern macOS interface (SwiftUI based)
- heavily GPU accelerated (almost everything except loading and sorting)
- supports really large maps in real time (tested with nside=8192)
- high quality map output (Lanczos oversampling built in, GPU accelerated)
- integrates into your workflow - drag & drop maps into Keynote/PowerPoint, etc.
- shortcuts for common analysis actions - statistics, PDF, data transforms
- extensible architecture - easily add your own colormaps, transforms, etc.
- entire source code available (Swift, C, Metal), about 5.2k lines

### Caveats:
- requires macOS 12, some features (notably charts) need macOS 13+ to run
- multiple GPUs are not supported, currently uses first one on device list
- memory hungry: nside=2048 map needs 1.3Gb of available VRAM
- maximal texture size and output image dimensions are limited to 16384
- this is a one man show, so no heavy testing on different platforms so far
- feature requests are welcome, but some are harder to implement than others
