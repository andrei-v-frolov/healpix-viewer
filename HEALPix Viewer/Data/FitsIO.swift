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
    case naxis = "NAXIS"
    case naxis1 = "NAXIS1"
    case naxis2 = "NAXIS2"
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
    static let required: [Self] = [.naxis, .naxis1, .naxis2, .fields,
                                   .healpix, .indexing, .ordering, .nside,
                                   .firstpix, .lastpix, .baddata, .polar, .polconv]
    static let recommended: [Self] = [.object, .coords, .temptype]
    static let optional: [Self] = []
    static let extended: [Self] = [.vector, .vframe]
    
    // read card (returning a proper data type)
    func read(_ fptr: UnsafeMutablePointer<fitsfile>?) -> FitsType? {
        switch self {
        case .naxis, .naxis1, .naxis2, .fields, .nside, .firstpix, .lastpix:
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
            case .naxis:    return FitsType.int(2)
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

// ...
typealias Cards = [HpxCard: FitsType]
typealias Metadata = [[MapCard: FitsType]?]

// typeset HDU header in human-readable form, as opposed to String(cString: header)
func typeset_header(_ header: UnsafeMutablePointer<CChar>, nkeys: Int32) -> String {
    var info = ""; for i in 0..<Int(nkeys) {
        if let card = NSString(bytes: header + 80*i, length: 80, encoding: NSASCIIStringEncoding) {
            info += (card as String) + "\n"
        }
    }
    
    return info
}

// read BINTABLE content, returning data as raw byte arrays
func read_bintable(_ fptr: UnsafeMutablePointer<fitsfile>?, nside: Int, nmaps: Int, nrows: Int, metadata: Metadata) -> (type: [Int32], data: [UnsafeMutableRawPointer])? {
    let npix = 12*nside*nside
    var status: Int32 = 0
    
    // parse data layout for all columns & allocate data buffers
    var format = [String](repeating: "", count: nmaps)
    var type = [Int32](repeating: 0, count: nmaps)
    var count = [Int](repeating: 0, count: nmaps)
    var width = [Int](repeating: 0, count: nmaps)
    var data = [UnsafeMutableRawPointer](); data.reserveCapacity(nmaps)
    
    for m in 0..<nmaps {
        if let v = metadata[m]?[.format], case let .string(s) = v { format[m] = s }
        format[m].withCString { s in let _ = ffbnfm(UnsafeMutablePointer(mutating: s), &type[m], &count[m], &width[m], &status) }
        guard (status == 0 && count[m] > 0 && width[m] > 0) else { return nil }
        //if (count[m]*nrows != npix) { print("row count mismatch for column \(m+1)?") }
        
        data.append(UnsafeMutableRawPointer.allocate(byteCount: npix*width[m], alignment: 8))
    }
    
    // determine optimal row chunk size (according to cfitsio)
    var chunk = 0; ffgrsz(fptr, &chunk, &status); chunk = max(chunk,1)
    guard (status == 0) else { return nil }
    
    // read chunked column data into buffers
    var i = [Int](repeating: 0, count: nmaps)
    var j = [Int](repeating: 0, count: nmaps)
    
    for frow in stride(from: 1, through: nrows, by: chunk) {
        for m in 0..<nmaps {
            j[m] = min(i[m]+chunk*count[m], npix) - 1; let n = j[m]-i[m]+1
            ffgcv(fptr, type[m], Int32(m+1), Int64(frow), 1, Int64(n), nil, data[m] + i[m]*width[m], nil, &status)
            guard (status == 0) else { return nil }
            i[m] = j[m]+1
        }
    }
    
    //if !(i.allSatisfy {$0 == npix}) { print("something went wrong during piecewise read?") }
    
    return (type, data)
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
    var nrows = 0; if let v = card[.naxis2], case let .int(n) = v { nrows = n }
    guard nside > 0, nmaps > 0, nrows > 0 else { return }
    
    // process metadata for all maps
    var metadata = Metadata(); metadata.reserveCapacity(nmaps)
    for i in 1...nmaps { metadata.append(MapCard.parse(fptr, map: i)) }
    
    print(metadata)
    
    // full sky map (without pixel index)
    if card[.indexing] == .string("IMPLICIT") {
        if let object = card[.object] { guard object == .string("FULLSKY") else { return } }
        
        print("Full sky map")
        
        guard let (type, data) = read_bintable(fptr, nside: nside, nmaps: nmaps, nrows: nrows, metadata: metadata) else { return }
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
