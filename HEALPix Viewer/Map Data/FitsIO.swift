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

// HEALPix ordering string literals
let NESTED = "NESTED", RING = "RING"

// CFITSIO data type sizes
private let sizeof = [
    TFLOAT:     MemoryLayout<Float>.size,
    TDOUBLE:    MemoryLayout<Double>.size,
    TSHORT:     MemoryLayout<Int16>.size,
    TINT:       MemoryLayout<Int32>.size,
    TLONG:      MemoryLayout<Int>.size,
    TLONGLONG:  MemoryLayout<Int64>.size
]

// enumeration encapsulating FITS data types
enum FitsType: Equatable {
    case int(Int)
    case float(Float)
    case double(Double)
    case string(String)
    case bool(Bool)
    
    // read typed FITS value
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
    case indexing = "INDXSCHM"  // omitted before 2012; fallback provided
    case ordering = "ORDERING"  // ABSOLUTELY needed for correct decoding
    case nside = "NSIDE"        // ABSOLUTELY needed for correct decoding
    case observed = "OBS_NPIX"  // needed for 'EXPLICIT' index decoding
    case firstpix = "FIRSTPIX"  // omitted in Planck Legacy Archive; made optional
    case lastpix = "LASTPIX"    // omitted in Planck Legacy Archive; made optional
    case baddata = "BAD_DATA"   // omitted in WMAP before 2012; fallback provided
    case polar = "POLAR"        // omitted in Planck Legacy Archive; fallback provided
    case polconv = "POLCCONV"   // present in Planck Legacy Archive; fallback provided
    
    // HEALPix recommended cards
    case object = "OBJECT"      // checked if present, fallback for 'INDXSCHM'
    case coords = "COORDSYS"    // ignored for now
    case temptype = "TEMPTYPE"  // checked when looking up temperature units
    
    // Planck frequency data cards
    case freq = "FREQ"          // map frequency
    case band = "BNDCTR"        // band center
    case feff = "RESTFRQ"       // effective frequency
    case falt = "RESTFREQ"      // alternate spelling
    case bandwidth = "BNDWID"   // approximate bandwidth
    case funit = "UNITFREQ"     // frequency units
    
    // my vector extensions
    case vector = "VECTOR"
    case vframe = "VFRAME"
    
    // collections
    static let required: [Self] = [.naxis, .naxis1, .naxis2, .fields,
                                   .healpix, .indexing, .ordering, .nside,
                                   .baddata, .polar, .polconv]
    static let optional: [Self] = [.firstpix, .lastpix]
    static let planck: [Self] = [.freq, .band, .feff, .bandwidth, .funit]
    static let mine: [Self] = [.vector, .vframe]
    static let extended: [Self] = planck + mine
    static let recommended: [Self] = [.object, .coords, .temptype]
    static let strict: [Self] = required + optional
    
    // read card (returning a proper data type)
    func read(_ fptr: UnsafeMutablePointer<fitsfile>?) -> FitsType? {
        switch self {
        case .naxis, .naxis1, .naxis2, .fields, .nside, .observed, .firstpix, .lastpix:
            return FitsType.readInt(fptr, key: self.rawValue)
        case .healpix, .indexing, .ordering, .object, .coords, .temptype, .polconv, .funit, .vframe:
            return FitsType.readString(fptr, key: self.rawValue)
        case .baddata, .freq, .band, .feff, .falt, .bandwidth:
            return FitsType.readFloat(fptr, key: self.rawValue)
        case .polar, .vector:
            return FitsType.readBool(fptr, key: self.rawValue)
        }
    }
    
    // mandatory values (if card is present, it MUST have this value)
    static let mandatory: [Self: FitsType] = [
        .naxis:     .int(2),
        .healpix:   .string("HEALPIX"),
        .baddata:   .float(BAD_DATA)
    ]
    
    // alternate cards (if card is absent, this card is tried instead)
    static let alternate: [Self: Self] = [
        .indexing:  .object,
        .observed:  .naxis2,
        .freq:      .band,
        .feff:      .falt
    ]
    
    // fallback values (if card is absent, this value is assumed)
    static let fallback: [Self: FitsType] = [
        .indexing: .string("IMPLICIT"),
        .baddata:  .float(BAD_DATA),
        .polar:    .bool(false),
        .polconv:  .string("COSMO")
    ]
    
    // parse HEALPix header
    static func parse(_ fptr: UnsafeMutablePointer<fitsfile>?) -> [Self: FitsType]? {
        var card = [Self: FitsType]()
        
        for k in Self.allCases {
            let value = k.read(fptr) ?? alternate[k]?.read(fptr) ?? fallback[k]
            if let x = mandatory[k] { guard value == x else { return nil } }
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
            case "TEMPERATURE", "I_STOKES", "I", "T":   return .i
            case "Q_POLARISATION", "Q_STOKES", "Q":     return .q
            case "U_POLARISATION", "U_STOKES", "U":     return .u
            case "E_POLARISATION", "E":                 return .e
            case "B_POLARISATION", "B":                 return .b
            case "P_POLARISATION", "P":                 return .p
            case "X_VECTOR", "X":                       return .x
            case "Y_VECTOR", "Y":                       return .y
            case "V_VECTOR", "V":                       return .v
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
private func typeset_header(_ header: UnsafePointer<CChar>, nkeys: Int32) -> String {
    var info = ""; for i in 0..<Int(nkeys) {
        if let card = NSString(bytes: header + 80*i, length: 80, encoding: NSASCIIStringEncoding) {
            info += (card as String) + "\n"
        }
    }
    
    return info
}

// read BINTABLE format, returning CFITSIO numeric types
private func read_format(_ fptr: UnsafeMutablePointer<fitsfile>?, metadata: Metadata) -> [Int32] {
    return metadata.map {
        var type: Int32 = 0, status: Int32 = 0; guard case let .string(s) = $0?[.format] else { return 0 }
        s.withCString { s in let _ = ffbnfm(UnsafeMutablePointer(mutating: s), &type, nil, nil, &status) }
        return (status == 0) ? type : 0
    }
}

// read BINTABLE content, returning data as raw byte arrays
private func read_table(_ fptr: UnsafeMutablePointer<fitsfile>?, npix: Int, nmaps: Int, nrows: Int, type: [Int32]) -> [UnsafeRawPointer]? {
    var type = type, status: Int32 = 0, cleanup = true
    
    // allocate buffer storage
    var data = [UnsafeMutableRawPointer?](); data.reserveCapacity(nmaps)
    defer { if (cleanup) { for p in data { if let p = p { p.deallocate() } } } }
    
    for m in 0..<nmaps {
        guard let width = sizeof[type[m]] else { return nil }
        data.append(UnsafeMutableRawPointer.allocate(byteCount: npix*width, alignment: 32))
    }
    
    // read entire table in
    var cols = Array(1...Int32(nmaps))
    var nuls = [UnsafeMutableRawPointer?](repeating: nil, count: nmaps)
    
    ffgcvn(fptr, Int32(nmaps), &type, &cols, 1, Int64(nrows), &nuls, &data, nil, &status)
    guard status == 0, data.allSatisfy({ $0 != nil }) else { return nil }
    
    cleanup = false; return data.map { UnsafeRawPointer($0!) }
}

// convert raw full-sky map data into canonical format (full-sky NESTED float)
private func raw2map(_ ptr: UnsafeRawPointer, nside: Int, type: Int32, order: String, flip: Bool = false) -> CpuMap? {
    let npix = 12*nside*nside; var cleanup = true, minval = 0.0, maxval = 0.0
    
    // allocate output buffer
    let output = UnsafeMutablePointer<Float>.allocate(capacity: npix)
    defer { if (cleanup) { output.deallocate() } }
    
    switch type {
        case TFLOAT: let buffer = ptr.bindMemory(to: Float.self, capacity: npix)
            switch (order, flip) {
                case (RING,   false): raw2map_frp(buffer, output, nside, &minval, &maxval)
                case (RING,   true ): raw2map_frn(buffer, output, nside, &minval, &maxval)
                case (NESTED, false): raw2map_fnp(buffer, output, nside, &minval, &maxval)
                case (NESTED, true ): raw2map_fnn(buffer, output, nside, &minval, &maxval)
                default: return nil
            }
        case TDOUBLE: let buffer = ptr.bindMemory(to: Double.self, capacity: npix)
            switch (order, flip) {
                case (RING,   false): raw2map_drp(buffer, output, nside, &minval, &maxval)
                case (RING,   true ): raw2map_drn(buffer, output, nside, &minval, &maxval)
                case (NESTED, false): raw2map_dnp(buffer, output, nside, &minval, &maxval)
                case (NESTED, true ): raw2map_dnn(buffer, output, nside, &minval, &maxval)
                default: return nil
            }
        case TSHORT: let buffer = ptr.bindMemory(to: Int16.self, capacity: npix)
            switch (order, flip) {
                case (RING,   false): raw2map_srp(buffer, output, nside, &minval, &maxval)
                case (RING,   true ): raw2map_srn(buffer, output, nside, &minval, &maxval)
                case (NESTED, false): raw2map_snp(buffer, output, nside, &minval, &maxval)
                case (NESTED, true ): raw2map_snn(buffer, output, nside, &minval, &maxval)
                default: return nil
            }
        case TINT: let buffer = ptr.bindMemory(to: Int32.self, capacity: npix)
            switch (order, flip) {
                case (RING,   false): raw2map_irp(buffer, output, nside, &minval, &maxval)
                case (RING,   true ): raw2map_irn(buffer, output, nside, &minval, &maxval)
                case (NESTED, false): raw2map_inp(buffer, output, nside, &minval, &maxval)
                case (NESTED, true ): raw2map_inn(buffer, output, nside, &minval, &maxval)
                default: return nil
            }
        case TLONG: let buffer = ptr.bindMemory(to: Int.self, capacity: npix)
            switch (order, flip) {
                case (RING,   false): raw2map_lrp(buffer, output, nside, &minval, &maxval)
                case (RING,   true ): raw2map_lrn(buffer, output, nside, &minval, &maxval)
                case (NESTED, false): raw2map_lnp(buffer, output, nside, &minval, &maxval)
                case (NESTED, true ): raw2map_lnn(buffer, output, nside, &minval, &maxval)
                default: return nil
            }
        case TLONGLONG: let buffer = ptr.bindMemory(to: Int64.self, capacity: npix)
            switch (order, flip) {
                case (RING,   false): raw2map_xrp(buffer, output, nside, &minval, &maxval)
                case (RING,   true ): raw2map_xrn(buffer, output, nside, &minval, &maxval)
                case (NESTED, false): raw2map_xnp(buffer, output, nside, &minval, &maxval)
                case (NESTED, true ): raw2map_xnn(buffer, output, nside, &minval, &maxval)
                default: return nil
            }
        default: return nil
    }
    
    cleanup = false; return CpuMap(nside: nside, buffer: output, min: minval, max: maxval)
}

// convert indexed partial map data into canonical format (full-sky NESTED float)
private func idx2map(_ idx: UnsafePointer<Int>, _ ptr: UnsafeRawPointer, nobs: Int, nside: Int, type: Int32, flip: Bool = false) -> CpuMap? {
    let npix = 12*nside*nside; var cleanup = true, minval = 0.0, maxval = 0.0
    
    // allocate output buffer (and initialize to NaN)
    let output = UnsafeMutablePointer<Float>.allocate(capacity: npix)
    output.initialize(repeating: .nan, count: npix)
    defer { if (cleanup) { output.deallocate() } }
    
    switch type {
        case TFLOAT: let buffer = ptr.bindMemory(to: Float.self, capacity: nobs)
            switch flip {
                case false: idx2map_fp(idx, buffer, output, nobs, &minval, &maxval)
                case true:  idx2map_fn(idx, buffer, output, nobs, &minval, &maxval)
            }
        case TDOUBLE: let buffer = ptr.bindMemory(to: Double.self, capacity: nobs)
            switch flip {
                case false: idx2map_dp(idx, buffer, output, nobs, &minval, &maxval)
                case true:  idx2map_dn(idx, buffer, output, nobs, &minval, &maxval)
            }
        case TSHORT: let buffer = ptr.bindMemory(to: Int16.self, capacity: nobs)
            switch flip {
                case false: idx2map_sp(idx, buffer, output, nobs, &minval, &maxval)
                case true:  idx2map_sn(idx, buffer, output, nobs, &minval, &maxval)
            }
        case TINT: let buffer = ptr.bindMemory(to: Int32.self, capacity: nobs)
            switch flip {
                case false: idx2map_ip(idx, buffer, output, nobs, &minval, &maxval)
                case true:  idx2map_in(idx, buffer, output, nobs, &minval, &maxval)
            }
        case TLONG: let buffer = ptr.bindMemory(to: Int.self, capacity: nobs)
            switch flip {
                case false: idx2map_lp(idx, buffer, output, nobs, &minval, &maxval)
                case true:  idx2map_ln(idx, buffer, output, nobs, &minval, &maxval)
            }
        case TLONGLONG: let buffer = ptr.bindMemory(to: Int64.self, capacity: nobs)
            switch flip {
                case false: idx2map_xp(idx, buffer, output, nobs, &minval, &maxval)
                case true:  idx2map_xn(idx, buffer, output, nobs, &minval, &maxval)
            }
        default: return nil
    }
    
    cleanup = false; return CpuMap(nside: nside, buffer: output, min: minval, max: maxval)
}

// validate and convert pixel index into canonical format (NESTED Int)
private func reindex(_ ptr: UnsafeRawPointer, nobs: Int, nside: Int, type: Int32, order: String) -> UnsafePointer<Int>? {
    var cleanup = true
    
    // allocate pixel index LUT
    let idx = UnsafeMutablePointer<Int>.allocate(capacity: nobs)
    defer { if (cleanup) { idx.deallocate() } }
    
    switch type {
        case TSHORT: let buffer = ptr.bindMemory(to: Int16.self, capacity: nobs)
            switch order {
                case RING:   guard reindex_sr(buffer, idx, nobs, nside) == 0 else { return nil }
                case NESTED: guard reindex_sn(buffer, idx, nobs, nside) == 0 else { return nil }
                default: return nil
            }
        case TINT: let buffer = ptr.bindMemory(to: Int32.self, capacity: nobs)
            switch order {
                case RING:   guard reindex_ir(buffer, idx, nobs, nside) == 0 else { return nil }
                case NESTED: guard reindex_in(buffer, idx, nobs, nside) == 0 else { return nil }
                default: return nil
            }
        case TLONG: let buffer = ptr.bindMemory(to: Int.self, capacity: nobs)
            switch order {
                case RING:   guard reindex_lr(buffer, idx, nobs, nside) == 0 else { return nil }
                case NESTED: guard reindex_ln(buffer, idx, nobs, nside) == 0 else { return nil }
                default: return nil
            }
        case TLONGLONG: let buffer = ptr.bindMemory(to: Int64.self, capacity: nobs)
            switch order {
                case RING:   guard reindex_xr(buffer, idx, nobs, nside) == 0 else { return nil }
                case NESTED: guard reindex_xn(buffer, idx, nobs, nside) == 0 else { return nil }
                default: return nil
            }
        default: return nil
    }
    
    cleanup = false; return UnsafePointer(idx)
}

// structure encapsulating contents of HEALPix file
struct HpxFile {
    let url: URL
    let name: String
    
    let nmaps: Int
    let header: String
    let parsed: Cards
    
    let data: [CpuMap]
    let list: [MapData]
    let metadata: Metadata
    let channel: [DataSource: Int]
    
    // map indexing
    subscript(index: Int) -> CpuMap { return data[index] }
    subscript(source: DataSource) -> CpuMap? {
        if let c = channel[source] { return data[c] } else { return nil }
    }
    
    // reload on restore
    var bookmark: Data? { try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess]) }
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
    guard case let .string(order) = card[.ordering] else { return nil }
    let iau = (card[.polar] == .bool(true)) && (card[.polconv] == .string("IAU"))
    
    // find nmaps and nside values
    var nside = 0; if case let .int(n) = card[.nside]  { nside = n }
    var nmaps = 0; if case let .int(n) = card[.fields] { nmaps = n }
    var nrows = 0; if case let .int(n) = card[.naxis2] { nrows = n }
    guard nside > 0, nmaps > 0, nrows > 0 else { return nil }
    
    // process metadata for all maps
    var metadata = (1...nmaps).map { MapCard.parse(fptr, map: $0) }
    
    // maps contained in the file (we will own their UnsafeBuffers!)
    let type = read_format(fptr, metadata: metadata)
    var maps = [CpuMap](); maps.reserveCapacity(nmaps)
    var list = [MapData](); list.reserveCapacity(nmaps)
    
    // full sky map (without pixel index)
    if card[.indexing] == .string("IMPLICIT") || card[.indexing] == .string("FULLSKY") {
        if let object = card[.object] { guard object == .string("FULLSKY") else { return nil } }
        
        // number of pixels in a map
        let npix = 12*nside*nside
        
        // diagnostic output
        print("Full sky map (nside = \(nside), nmaps = \(nmaps), \(order) ordering), \(npix) pixels")
        
        // read in raw HEALPix data (we own these UnsafeBuffers!)
        guard let data = read_table(fptr, npix: npix, nmaps: nmaps, nrows: nrows, type: type) else { return nil }
        defer { for p in data { p.deallocate() } }
        
        // convert to canonical map format
        for m in 0..<nmaps {
            let flip = iau && (MapCard.type(metadata[m]?[.type]) == .u)
            
            if let c = raw2map(data[m], nside: nside, type: type[m], order: order, flip: flip) { maps.append(c) } else { return nil }
        }
    }
    else
    // indexed sky map (first column contains pixel index)
    if card[.indexing] == .string("EXPLICIT") || card[.indexing] == .string("PARTIAL") {
        //if let object = card[.object] { guard object == .string("PARTIAL") else { return nil } }
        guard nmaps > 1, let idx = metadata.first, idx?[.type] == .string("PIXEL") else { return nil }
        guard case let .int(nobs) = card[.observed] else { return nil }
        
        // diagnostic output
        print("Indexed sky map (nside = \(nside), nmaps = \(nmaps-1), \(order) ordering), \(nobs) pixels")
        
        // read in raw HEALPix data (we own these UnsafeBuffers!)
        guard let data = read_table(fptr, npix: nobs, nmaps: nmaps, nrows: nrows, type: type) else { return nil }
        defer { for p in data { p.deallocate() } }
        
        // reindex pixels to canonical ordering (we own this UnsafeBuffer!)
        guard let idx = reindex(data[0], nobs: nobs, nside: nside, type: type[0], order: order) else { return nil }
        defer { idx.deallocate() }
        
        // convert to canonical map format
        for m in 1..<nmaps {
            let flip = iau && (MapCard.type(metadata[m]?[.type]) == .u)
            
            if let c = idx2map(idx, data[m], nobs: nobs, nside: nside, type: type[m], flip: flip) { maps.append(c) } else { return nil }
        }
        
        metadata.removeFirst(); nmaps -= 1
    } else { return nil }
    
    // index named data channels
    var index = [DataSource: Int]()
    
    for m in 0..<nmaps {
        if let t = metadata[m]?[.type], let type = MapCard.type(t) { index[type] = m }
        var desc = "CHANNEL \(m)"; if let t = metadata[m]?[.type], case let .string(s) = t { desc = s }
        var unit = "UNKNOWN";      if let u = metadata[m]?[.unit], case let .string(s) = u { unit = s }
        
        list.append(MapData(file: name, info: info, parsed: card, name: desc, unit: unit, channel: m, data: maps[m]))
    }
    
    return HpxFile(url: url, name: name, nmaps: nmaps, header: info, parsed: card, data: maps, list: list, metadata: metadata, channel: index)
}
