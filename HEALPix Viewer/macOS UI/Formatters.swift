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
