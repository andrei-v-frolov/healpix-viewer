//
//  Formatters.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-23.
//

import Foundation

// integer number formatter
let IntegerNumber: NumberFormatter = {
    let format = NumberFormatter()
    
    format.allowsFloats = false
    
    return format
}()

// number formatter common to most fields
let OneDigitNumber: NumberFormatter = {
    let format = NumberFormatter()
    
    format.minimumFractionDigits = 1
    format.maximumFractionDigits = 1
    format.isLenient = true
    
    return format
}()

// number formatter common to most fields
let TwoDigitNumber: NumberFormatter = {
    let format = NumberFormatter()
    
    format.minimumFractionDigits = 2
    format.maximumFractionDigits = 2
    format.isLenient = true
    
    return format
}()

// number formatter common to most fields
let SixDigitsScientific: NumberFormatter = {
    let format = NumberFormatter()
    
    format.numberStyle = .scientific
    format.usesSignificantDigits = true
    format.minimumSignificantDigits = 6
    format.maximumSignificantDigits = 6
    format.isLenient = true
    
    return format
}()

// texture size formatter
let SizeFormatter: NumberFormatter = {
    let n = IntegerNumber
    
    n.minimum = 0
    n.maximum = NSNumber(value: metal.maxTextureSize)
    
    return n
}()

// trivial string formatter
class AnyText: Formatter {
    override func string(for object: Any?) -> String? {
        guard let string = object as? String else { return nil }
        return string
    }
    
    override func getObjectValue(_ object: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        object?.pointee = string as AnyObject; return true
    }
}

// generic implementation of limiters
extension Comparable {
    mutating func above(_ value: Self) { self = max(self,value) }
    mutating func below(_ value: Self) { self = min(self,value) }
    mutating func clamp(_ a: Self, _ b: Self) { self = max(min(self,b),a) }
}

// compound assignment operators for booleans
infix operator ||=: AssignmentPrecedence; func ||=(a: inout Bool, b: Bool) { a = a || b }
infix operator &&=: AssignmentPrecedence; func &&=(a: inout Bool, b: Bool) { a = a && b }
