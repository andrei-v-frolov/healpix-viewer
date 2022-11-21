//
//  FileInput.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-15.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var healpix: UTType { UTType(exportedAs: "public.data.fits.healpix") }
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
