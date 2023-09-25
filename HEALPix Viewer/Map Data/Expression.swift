//
//  Expression.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-08-01.
//

import Foundation

// general operations on map data
enum Expression {
    // data sources
    case literal(Float)
    case random(RandomField)
    case map(MapData)
    
    // map transforms
    indirect case transform(Expression,Transform)
    
    // masking operators
    indirect case valid(Expression)
    indirect case invalid(Expression)
    indirect case mask(Expression,Expression)
    
    // arithmetic operators
    indirect case add(Expression,Expression)
    indirect case subtract(Expression,Expression)
    indirect case multiply(Expression,Expression)
    indirect case divide(Expression,Expression)
    indirect case power(Expression,Expression)
    
    // comparison operators
    indirect case equal(Expression,Expression)
    indirect case less(Expression,Expression)
    indirect case greater(Expression,Expression)
    indirect case ne(Expression,Expression)
    indirect case le(Expression,Expression)
    indirect case ge(Expression,Expression)
    
    // projection operators
    indirect case project(Expression,Expression)
    indirect case orthogonal(Expression,Expression)
}
