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

// non-fatal error panel
func error(_ header: String, _ message: String) {
    let alert = NSAlert()
    
    alert.alertStyle = .warning
    alert.messageText = header
    alert.informativeText = message
    alert.addButton(withTitle: "Dismiss")
    alert.runModal()
}

// fatal error panel
func abort(_ message: String) -> Never {
    let alert = NSAlert()
    
    alert.alertStyle = .critical
    alert.messageText = "Fatal Error"
    alert.informativeText = message
    alert.addButton(withTitle: "Exit")
    alert.runModal()
    
    NSApplication.shared.terminate(nil)
    fatalError(message)
}

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
func showSavePanel(type: UTType = .png) -> URL? {
    let panel = NSSavePanel()
    
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    
    panel.allowedContentTypes = [type]
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

// SwiftUI image from Metal texture
func image(_ texture: MTLTexture, oversample s: Double = 2.0) -> Image? {
    guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
          let image = CIImage(mtlTexture: texture, options: [.colorSpace: srgb]) else { return nil }
    
    let nsimage = NSImage(size: NSSize(width: image.extent.width/s, height: image.extent.height/s))
    nsimage.addRepresentation(NSBitmapImageRep(ciImage: image))
    return Image(nsImage: nsimage)
}

// image data from Metal texture
func imagedata(_ texture: MTLTexture, format: ImageFormat = .png) -> Data? {
    guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
          let image = CIImage(mtlTexture: texture, options: [.colorSpace: srgb]) else { return nil }
    
    switch format {
        case .gif: return NSBitmapImageRep(ciImage: image).representation(using: .gif, properties: [:])
        case .png: return NSBitmapImageRep(ciImage: image).representation(using: .png, properties: [:])
        case .heif: return CIContext().heifRepresentation(of: image, format: .RGBA8, colorSpace: srgb)
        case .tiff: return CIContext().tiffRepresentation(of: image, format: .RGBA16, colorSpace: srgb)
    }
}

// save Metal texture to image file
func saveAsImage(_ texture: MTLTexture, url: URL? = nil, format: ImageFormat = .png) {
    guard let url = url ?? showSavePanel(type: format.type) else { return }
    userTaskQueue.async { try? imagedata(texture, format: format)?.write(to: url) }
}
