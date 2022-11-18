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
    case healpix = "PIXTYPE"    // ABSOLUTELY needed (HEALPix format ID)
    case indexing = "INDXSCHM"  // omitted in WMAP before 2012; fallback provided
    case ordering = "ORDERING"  // ABSOLUTELY needed for correct decoding
    case nside = "NSIDE"        // ABSOLUTELY needed for correct decoding
    case firstpix = "FIRSTPIX"  // omitted in Planck Legacy Archive; made optional
    case lastpix = "LASTPIX"    // omitted in Planck Legacy Archive; made optional
    case baddata = "BAD_DATA"   // omitted in WMAP before 2012; fallback provided
    case polar = "POLAR"        // omitted in Planck Legacy Archive; fallback provided
    case polconv = "POLCCONV"   // present in Planck Legacy Archive; fallback provided
    
    // HEALPix recommended cards
    case object = "OBJECT"      // checked if present
    case coords = "COORDSYS"    // ignored for now
    case temptype = "TEMPTYPE"  // ignored for now
    
    // my vector extensions
    case vector = "VECTOR"
    case vframe = "VFRAME"
    
    // collections
    static let required: [Self] = [.naxis, .naxis1, .naxis2, .fields,
                                   .healpix, .indexing, .ordering, .nside,
                                   .baddata, .polar, .polconv]
    static let optional: [Self] = [.firstpix, .lastpix]
    static let extended: [Self] = [.vector, .vframe]
    static let recommended: [Self] = [.object, .coords, .temptype]
    static let strict: [Self] = required + optional

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
    
    // ID commonly used map types
    static func type(_ string: String) -> DataSource? {
        for t in DataSource.allCases { if (string == t.rawValue) { return t } }
        
        switch string {
            case "TEMPERATURE", "I_STOKES":     return .i
            case "Q_POLARISATION", "Q_STOKES":  return .q
            case "U_POLARISATION", "U_STOKES":  return .u
            case "E_POLARISATION":              return .e
            case "B_POLARISATION":              return .b
            case "P_POLARISATION":              return .p
            case "X_VECTOR":                    return .x
            case "Y_VECTOR":                    return .y
            case "V_VECTOR":                    return .v
            default: return nil
        }
    }
    
    static func type(_ value: FitsType?) -> DataSource? {
        if let v = value, case let .string(s) = v { return type(s) } else { return nil }
    }
}

// convenience types for cards and per-map metadata
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
func read_bintable(_ fptr: UnsafeMutablePointer<fitsfile>?, npix: Int, nmaps: Int, nrows: Int, metadata: Metadata) -> (type: [Int32], data: [UnsafeMutableRawPointer])? {
    var status: Int32 = 0, cleanup = true
    
    // determine optimal row chunk size (according to cfitsio)
    var chunk = 0; ffgrsz(fptr, &chunk, &status); chunk = max(chunk,1)
    guard (status == 0) else { return nil }
    
    // parse data layout for all columns & allocate data buffers
    var type = [Int32](repeating: 0, count: nmaps)
    var count = [Int](repeating: 0, count: nmaps)
    var width = [Int](repeating: 0, count: nmaps)
    
    var data = [UnsafeMutableRawPointer](); data.reserveCapacity(nmaps)
    defer { if (cleanup) { for p in data { p.deallocate() } } }
    
    for m in 0..<nmaps {
        if let v = metadata[m]?[.format], case let .string(s) = v {
            s.withCString { s in let _ = ffbnfm(UnsafeMutablePointer(mutating: s), &type[m], &count[m], &width[m], &status) }
        }
        guard (status == 0 && count[m] > 0 && width[m] > 0) else { return nil }
        //if (count[m]*nrows != npix) { print("row count mismatch for column \(m+1)?") }
        
        data.append(UnsafeMutableRawPointer.allocate(byteCount: npix*width[m], alignment: 8))
    }
    
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
    
    cleanup = false; return (type, data)
}

// convert raw full-sky map data into canonical format (full-sky NESTED float)
func raw2map_full(_ ptr: UnsafeMutableRawPointer, nside: Int, type: Int32, order: FitsType, flip: Bool) -> CpuMap? {
    let npix = 12*nside*nside; var cleanup = true, minval = 0.0, maxval = 0.0
    let output = UnsafeMutablePointer<Float>.allocate(capacity: npix)
    defer { if (cleanup) { output.deallocate() } }
    
    if type == TFLOAT, case let .string(value) = order {
        let buffer = ptr.bindMemory(to: Float.self, capacity: npix)
        
        switch (value, flip) {
            case ("RING",   false): raw2map_ffrp(buffer, output, nside, &minval, &maxval)
            case ("RING",   true ): raw2map_ffrn(buffer, output, nside, &minval, &maxval)
            case ("NESTED", false): raw2map_ffnp(buffer, output, nside, &minval, &maxval)
            case ("NESTED", true ): raw2map_ffnn(buffer, output, nside, &minval, &maxval)
            default: return nil
        }
    }
    else
    if type == TDOUBLE, case let .string(value) = order {
        let buffer = ptr.bindMemory(to: Double.self, capacity: npix)
        
        switch (value, flip) {
            case ("RING",   false): raw2map_fdrp(buffer, output, nside, &minval, &maxval)
            case ("RING",   true ): raw2map_fdrn(buffer, output, nside, &minval, &maxval)
            case ("NESTED", false): raw2map_fdnp(buffer, output, nside, &minval, &maxval)
            case ("NESTED", true ): raw2map_fdnn(buffer, output, nside, &minval, &maxval)
            default: return nil
        }
    }
    else { return nil }
    
    cleanup = false; return CpuMap(nside: nside, buffer: output, min: minval, max: maxval)
}

// structure encapsulating contents of HEALPix file
struct HpxFile {
    let url: URL
    let name: String
    
    let nmaps: Int
    let header: String
    let card: Cards?
    
    let map: [Map]
    let list: [MapData]
    let metadata: Metadata
    let channel: [DataSource: Int]
    
    // map indexing
    subscript(index: Int) -> Map { return map[index] }
    subscript(data: DataSource) -> Map? {
        if let c = channel[data] { return map[c] } else { return nil }
    }
}

// read entire contents of HEALPix file
func read_hpxfile(url: URL) -> HpxFile? {
    guard url.isFileURL else { return nil }
    let file = url.path, name = url.lastPathComponent
    
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
    guard (status == 0) else { return nil }
    
    // check the number of the current HDU (should not be primary)
    ffghdn(fptr, &hdu)
    guard (hdu > 1) else { return nil }
    
    // check the type of the current HDU (should be BINARY_TBL)
    ffghdt(fptr, &hdu, &status)
    guard (status == 0 && hdu == BINARY_TBL) else { return nil }
    
    // read in the entire HDU header
    ffhdr2str(fptr, 0, nil, 0, &header, &nkeys, &status)
    guard (status == 0), let header = header else { return nil }
    
    // typeset and parse header
    let info = typeset_header(header, nkeys: nkeys)
    guard let card = HpxCard.parse(fptr) else { return nil }
    guard let order = card[.ordering] else { return nil }
    let iau = (card[.polar] == .bool(true)) && (card[.polconv] == .string("IAU"))
    
    // find nmaps and nside values
    var nside = 0; if let v = card[.nside], case let .int(n) = v { nside = n }
    var nmaps = 0; if let v = card[.fields], case let .int(n) = v { nmaps = n }
    var nrows = 0; if let v = card[.naxis2], case let .int(n) = v { nrows = n }
    guard nside > 0, nmaps > 0, nrows > 0 else { return nil }
    
    // process metadata for all maps
    var metadata = Metadata(); metadata.reserveCapacity(nmaps)
    for i in 1...nmaps { metadata.append(MapCard.parse(fptr, map: i)) }
    
    // maps contained in the file (we will own their UnsafeBuffers!)
    var map = [CpuMap](); map.reserveCapacity(nmaps)
    var list = [MapData](); list.reserveCapacity(nmaps)
    
    // full sky map (without pixel index)
    if card[.indexing] == .string("IMPLICIT") {
        if let object = card[.object] { guard object == .string("FULLSKY") else { return nil } }
        
        print("Full sky map, nside = \(nside), nmaps = \(nmaps)")
        let npix = 12*nside*nside
        
        // read in raw HEALPix data (we own these UnsafeBuffers!)
        guard let (type, data) = read_bintable(fptr, npix: npix, nmaps: nmaps, nrows: nrows, metadata: metadata) else { return nil }
        
        // convert to canonical map format
        for m in 0..<nmaps {
            let flip =  iau && (MapCard.type(metadata[m]?[.type]) == .u)
            
            if let c = raw2map_full(data[m], nside: nside, type: type[m], order: order, flip: flip) { map.append(c) } else { for p in data { p.deallocate() }; return nil }
        }
        
        for p in data { p.deallocate() }
    }
    else
    // partial sky map (first column contains pixel index)
    if card[.indexing] == .string("EXPLICIT") && nmaps > 1 {
        if let object = card[.object] { guard object == .string("PARTIAL") else { return nil } }
        
        // check that the first column format is integer
        let idx = metadata.removeFirst(); nmaps -= 1
        if let format = idx?[.format] { guard format == .string("J") || format == .string("K") else { return nil } }
        
        print("Partial sky map is not supported yet..."); return nil
    } else { return nil }
    
    // index named data channels
    var index = [DataSource: Int]()
    
    for m in 0..<nmaps {
        if let t = metadata[m]?[.type], let type = MapCard.type(t) { index[type] = m }
        var desc = "CHANNEL \(m)"; if let t = metadata[m]?[.type], case let .string(s) = t { desc = s }
        var unit = "UNKNOWN";      if let u = metadata[m]?[.unit], case let .string(s) = u { unit = s }
        
        list.append(MapData(id: UUID(), file: name, info: info, name: desc, unit: unit, channel: m, map: map[m]))
    }
    
    return HpxFile(url: url, name: name, nmaps: nmaps, header: info, card: card, map: map, list: list, metadata: metadata, channel: index)
}
