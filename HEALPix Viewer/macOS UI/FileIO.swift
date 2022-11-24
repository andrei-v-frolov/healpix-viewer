//
//  FileIO.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-15.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var healpix: UTType { UTType(exportedAs: "public.data.fits.healpix") }
}

// list of temporary files to clean up
var tmpfiles = [URL]()

// show modal Open File panel
func showOpenPanel() -> URL? {
    let panel = NSOpenPanel()
    
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.isExtensionHidden = false
    
    panel.allowedContentTypes = [UTType.healpix]
    panel.allowsOtherFileTypes = true
    
    let response = panel.runModal()
    return (response == .OK) ? panel.url : nil
}

// show modal Save File panel
func showSavePanel() -> URL? {
    let panel = NSSavePanel()
    
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    
    panel.allowedContentTypes = [UTType.png]
    panel.allowsOtherFileTypes = true
    
    let response = panel.runModal()
    return (response == .OK) ? panel.url : nil
}

// temporary file URL
func tmpfile(name: String = UUID().uuidString, type: UTType = .png) -> URL? {
    let finder = FileManager.default, home = finder.homeDirectoryForCurrentUser
    let dir = try? finder.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: home, create: true)
    
    return dir?.appendingPathComponent(name, conformingTo: type)
}

// PNG image data from Metal texture
func pngdata(_ texture: MTLTexture) -> Data? {
    guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
          let image = CIImage(mtlTexture: texture, options: [.colorSpace: srgb]) else { return nil }
    return NSBitmapImageRep(ciImage: image).representation(using: .png, properties: [:])
}

// save Metal texture to PNG image file
func saveAsPNG(_ texture: MTLTexture, url: URL? = nil) {
    guard let url = url ?? showSavePanel() else { return }
    try? pngdata(texture)?.write(to: url)
}
