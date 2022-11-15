//
//  FitsIO.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-14.
//

import Foundation
import CFitsIO

// HEALPix bad data guard value
let BAD_DATA: Float = -1.6375000E+30

// enumeration encapsulating FITS data types
enum FitsType: Equatable {
    case int(Int)
    case float(Float)
    case double(Double)
    case string(String)
    case bool(Bool)
    
    static func readInt(_ fptr: UnsafeMutablePointer<fitsfile>?, key: String) -> Self? {
        var value: Int = 0, status: Int32 = 0
        ffgkyj(fptr, key, &value, nil, &status)
        guard (status == 0) else { return nil }
        
        return .int(value)
    }
    
    static func readFloat(_ fptr: UnsafeMutablePointer<fitsfile>?, key: String) -> Self? {
        var value: Float = 0, status: Int32 = 0
        ffgkye(fptr, key, &value, nil, &status)
        guard (status == 0) else { return nil }
        
        return .float(value)
    }
    
    static func readDouble(_ fptr: UnsafeMutablePointer<fitsfile>?, key: String) -> Self? {
        var value: Double = 0, status: Int32 = 0
        ffgkyd(fptr, key, &value, nil, &status)
        guard (status == 0) else { return nil }
        
        return .double(value)
    }
    
    static func readString(_ fptr: UnsafeMutablePointer<fitsfile>?, key: String) -> Self? {
        var value = UnsafeMutablePointer<CChar>.allocate(capacity: 80), status: Int32 = 0
        ffgkys(fptr, key, value, nil, &status)
        guard (status == 0) else { return nil }
        
        return .string(String(cString: value))
    }
    
    static func readBool(_ fptr: UnsafeMutablePointer<fitsfile>?, key: String) -> Self? {
        var value: Int32 = 0, status: Int32 = 0
        ffgkyl(fptr, key, &value, nil, &status)
        guard (status == 0) else { return nil }
        
        return .bool(value != 0)
    }
}

// enumeration encapsulating HEALPix cards
enum HpxCard: String, CaseIterable {
    // FITS required cards
    case fields = "TFIELDS"
    
    // HEALPix required cards
    case healpix = "PIXTYPE"
    case indexing = "INDXSCHM"
    case ordering = "ORDERING"
    case nside = "NSIDE"
    case firstpix = "FIRSTPIX"
    case lastpix = "LASTPIX"
    case baddata = "BAD_DATA"
    case polar = "POLAR"
    case polconv = "POLCCONV"
    
    // HEALPix recommended cards
    case object = "OBJECT"
    case coords = "COORDSYS"
    case temptype = "TEMPTYPE"
    
    // my vector extensions
    case vector = "VECTOR"
    case vframe = "VFRAME"
    
    // collections
    static let required: [Self] = [.fields, .healpix, .indexing, .ordering, .nside,
                                   .firstpix, .lastpix, .baddata, .polar, .polconv]
    static let recommended: [Self] = [.object, .coords, .temptype]
    static let optional: [Self] = []
    static let extended: [Self] = [.vector, .vframe]
    
    // read card (returning a proper data type)
    func read(_ fptr: UnsafeMutablePointer<fitsfile>?) -> FitsType? {
        switch self {
        case .fields, .nside, .firstpix, .lastpix:
            return FitsType.readInt(fptr, key: self.rawValue)
        case .healpix, .indexing, .ordering, .object, .coords, .temptype, .polconv, .vframe:
            return FitsType.readString(fptr, key: self.rawValue)
        case .baddata:
            return FitsType.readFloat(fptr, key: self.rawValue)
        case .polar, .vector:
            return FitsType.readBool(fptr, key: self.rawValue)
        }
    }
    
    // mandatory values (if card is present, it must have this value)
    var mandatory: FitsType? {
        switch self {
            case .healpix:  return FitsType.string("HEALPIX")
            case .baddata:  return FitsType.float(BAD_DATA)
            default:        return nil
        }
    }
    
    // fallback values (if card is absent, this value is assumed)
    var fallback: FitsType? {
        switch self {
            case .indexing: return FitsType.string("IMPLICIT")
            case .baddata:  return FitsType.float(BAD_DATA)
            case .polar:    return FitsType.bool(false)
            case .polconv:  return FitsType.string("COSMO")
            default: return nil
        }
    }
    
    // parse HEALPix header
    static func parse(_ fptr: UnsafeMutablePointer<fitsfile>?) -> [Self: FitsType]? {
        var card = [Self: FitsType]()
        
        for k in Self.allCases {
            let value = k.read(fptr) ?? k.fallback
            if let x = k.mandatory { guard let v = value, v == x else { return nil } }
            if let v = value { card[k] = v }
        }
        
        for k in required { if (card[k] == nil) { return nil } }
        
        return card
    }
}

// enumeration encapsulating map metadata cards
enum MapCard: String, CaseIterable {
    case type = "TTYPE"
    case unit = "TUNIT"
    case format = "TFORM"
    
    // collections
    static let required: [Self] = [.format]
    
    // read card (returning a proper data type)
    func read(_ fptr: UnsafeMutablePointer<fitsfile>?, map: Int) -> FitsType? {
        return FitsType.readString(fptr, key: self.rawValue + "\(map)")
    }
    
    // parse map metadata
    static func parse(_ fptr: UnsafeMutablePointer<fitsfile>?, map: Int) -> [Self: FitsType]? {
        var card = [Self: FitsType]()
        
        for k in Self.allCases {
            if let value = k.read(fptr, map: map) { card[k] = value }
        }
        
        for k in required { if (card[k] == nil) { return nil } }
        
        return card
    }
}

// HDU header in human-readable form, as opposed to String(cString: header)
func typeset_header(_ header: UnsafeMutablePointer<CChar>, nkeys: Int32) -> String {
    var info = ""; for i in 0..<Int(nkeys) {
        if let card = NSString(bytes: header + 80*i, length: 80, encoding: NSASCIIStringEncoding) {
            info += (card as String) + "\n"
        }
    }
    
    return info
}

// ...
func getsize_fits(file: String) {
    var fptr: UnsafeMutablePointer<fitsfile>? = nil
    var header: UnsafeMutablePointer<CChar>? = nil
    var hdu: Int32 = 0, nkeys: Int32 = 0, status: Int32 = 0
    
    // clean up on exit
    defer {
        if (header != nil) { fffree(header, &status) }
        if (fptr != nil) { ffclos(fptr, &status) }
    }
    
    // open FITS file and move to first table HDU
    fftopn(&fptr, file, READONLY, &status)
    guard (status == 0) else { return }
    
    // check the number of the current HDU (should not be primary)
    ffghdn(fptr, &hdu)
    guard (hdu > 1) else { return }
    
    // check the type of the current HDU (should be BINARY_TBL)
    ffghdt(fptr, &hdu, &status)
    guard (status == 0 && hdu == BINARY_TBL) else { return }
    
    // read in the entire HDU header
    ffhdr2str(fptr, 0, nil, 0, &header, &nkeys, &status)
    guard (status == 0), let header = header else { return }
    
    // typeset and parse header
    let info = typeset_header(header, nkeys: nkeys)
    guard let card = HpxCard.parse(fptr) else { return }
    
    print(info)
    print(card)
    
    // find nmaps and nside values
    var nside = 0; if let v = card[.nside], case let .int(n) = v { nside = n }
    var nmaps = 0; if let v = card[.fields], case let .int(n) = v { nmaps = n }
    guard nside > 0, nmaps > 0 else { return }
    
    // process metadata for all maps
    var metadata = [[MapCard: FitsType]?](); metadata.reserveCapacity(nmaps)
    for i in 1...nmaps { metadata.append(MapCard.parse(fptr, map: i)) }
    
    print(metadata)
    
    // full sky map (without pixel index)
    if card[.indexing] == .string("IMPLICIT") {
        if let object = card[.object] { guard object == .string("FULLSKY") else { return } }
        
        print("Full sky map")
    }
    
    // partial sky map (first column contains pixel index)
    if card[.indexing] == .string("EXPLICIT") && nmaps > 1 {
        if let object = card[.object] { guard object == .string("PARTIAL") else { return } }
        
        // check that the first column format is integer
        let idx = metadata.removeFirst(); nmaps -= 1
        if let format = idx?[.format] { guard format == .string("J") || format == .string("K") else { return } }
        
        print("Partial sky map")
    }
    
    // index named data channels
    var index = [DataSource: Int]()
    
    for i in 0..<nmaps {
        if let m = metadata[i], let t = m[.type], case let .string(s) = t {
            switch s {
                case "TEMPERATURE":     index[.i] = i
                case "Q_POLARISATION":  index[.q] = i
                case "U_POLARISATION":  index[.u] = i
                case "E_POLARISATION":  index[.e] = i
                case "B_POLARISATION":  index[.b] = i
                case "P_POLARISATION":  index[.p] = i
                case "X_VECTOR":        index[.x] = i
                case "Y_VECTOR":        index[.y] = i
                case "V_VECTOR":        index[.v] = i
                default: break
            }
        }
    }
    
    print(index)
}
