//
//  Icons.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2023-11-09.
//

import SwiftUI

// canvas rendering specific curve icons (scaled to fit 20x24 label)
enum Curve {
    static let width = 1.5
    
    // Gaussian statistics icon
    static let gaussian = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: -4.0, y: 0.0))
            path.addLine(to: CGPoint(x: -3.000000, y: 0.000123))
            path.addCurve(to: CGPoint(x: -1.500000, y: 0.105399),
                          control1: CGPoint(x: -2.201230, y: 0.000715),
                          control2: CGPoint(x: -1.832157, y: 0.000372))
            path.addCurve(to: CGPoint(x: -0.500000, y: 0.778801),
                          control1: CGPoint(x: -1.063884, y: 0.243298),
                          control2: CGPoint(x: -0.798121, y: 0.546624))
            path.addCurve(to: CGPoint(x: 0.500000, y: 0.778801),
                          control1: CGPoint(x: -0.120674, y: 1.074220),
                          control2: CGPoint(x: 0.120674, y: 1.074220))
            path.addCurve(to: CGPoint(x: 1.500000, y: 0.105399),
                          control1: CGPoint(x: 0.798121, y: 0.546624),
                          control2: CGPoint(x: 1.063884, y: 0.243298))
            path.addCurve(to: CGPoint(x: 3.000000, y: 0.000123),
                          control1: CGPoint(x: 1.832157, y: 0.000372),
                          control2: CGPoint(x: 2.201230, y: 0.000715))
            path.addLine(to: CGPoint(x: 4.0, y: 0.0))
        }
        .applying(CGAffineTransform(scaleX: 2.5, y: -13))
        .applying(CGAffineTransform(translationX: 10, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
        
        // full width half max annotation
        let fwhm = Path { path in
            path.move(to: CGPoint(x: -5.0, y: 0.5))
            path.addLine(to: CGPoint(x: -2.0, y: 0.5))
            path.move(to: CGPoint(x: -3.0, y: 0.7))
            path.addLine(to: CGPoint(x: -2.0, y: 0.5))
            path.addLine(to: CGPoint(x: -3.0, y: 0.3))
            
            path.move(to: CGPoint(x: 5.0, y: 0.5))
            path.addLine(to: CGPoint(x: 2.0, y: 0.5))
            path.move(to: CGPoint(x: 3.0, y: 0.7))
            path.addLine(to: CGPoint(x: 2.0, y: 0.5))
            path.addLine(to: CGPoint(x: 3.0, y: 0.3))
        }
        .applying(CGAffineTransform(scaleX: 2.5, y: -13))
        .applying(CGAffineTransform(translationX: 10, y: 18))
        context.stroke(fwhm, with: .foreground, lineWidth: width/2.0)
    }
    
    // linear transfer, clipped from above and below
    static let clip = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: -1.0, y: 0.0))
            path.addLine(to: CGPoint(x: 0.0, y: 0.0))
            path.addLine(to: CGPoint(x: 1.0, y: 1.0))
            path.addLine(to: CGPoint(x: 2.0, y: 1.0))
        }
        .applying(CGAffineTransform(scaleX: 6, y: -12))
        .applying(CGAffineTransform(translationX: 7, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
    }
    
    // filmic transfer, clipped from below
    static let film = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: -1.0, y: 0.0))
            path.addCurve(to: CGPoint(x: -0.7, y: 0.0),
                          control1: CGPoint(x:  0.0, y: 0.0),
                          control2: CGPoint(x: -1.0, y: 0.0))
            path.addCurve(to: CGPoint(x: 1.7, y: 1.0),
                          control1: CGPoint(x: 1.0, y: 0.0),
                          control2: CGPoint(x: 0.0, y: 1.0))
            path.addCurve(to: CGPoint(x: 2.0, y: 1.0),
                          control1: CGPoint(x: 1.0, y: 1.0),
                          control2: CGPoint(x: 2.0, y: 1.0))
        }
        .applying(CGAffineTransform(scaleX: 6, y: -12))
        .applying(CGAffineTransform(translationX: 7, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
    }
    
    // hybrid log-gamma transfer, clipped from below
    static let hlg = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: -1.0, y: 0.0))
            path.addLine(to: CGPoint(x: 0.0, y: 0.0))
            path.addLine(to: CGPoint(x: 0.250000, y: 0.290108))
            path.addCurve(to: CGPoint(x: 2.000000, y: 0.993546),
                          control1: CGPoint(x: 0.523778, y: 0.607809),
                          control2: CGPoint(x: 1.125000, y: 0.819328))
        }
        .applying(CGAffineTransform(scaleX: 6, y: -12))
        .applying(CGAffineTransform(translationX: 7, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
    }
    
    // linear transfer, clipped from below
    static let hdr = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: -1.0, y: 0.0))
            path.addLine(to: CGPoint(x: 0.0, y: 0.0))
            path.addLine(to: CGPoint(x: 2.0, y: 1.0))
        }
        .applying(CGAffineTransform(scaleX: 6, y: -12))
        .applying(CGAffineTransform(translationX: 7, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
    }
    
    // linear interpolation
    static let linear = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: 0.0, y: 0.0))
            path.addLine(to: CGPoint(x: 1.0, y: 2.0))
            path.addLine(to: CGPoint(x: 2.0, y: 1.0))
            path.addLine(to: CGPoint(x: 3.0, y: 3.0))
        }
        .applying(CGAffineTransform(scaleX: 6, y: -4))
        .applying(CGAffineTransform(translationX: 0, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
    }
    
    // cubic spline interpolation
    static let spline = Canvas { context, size in
        let path = Path { path in
            path.move(to: CGPoint(x: 0.0, y: 0.0))
            path.addCurve(to: CGPoint(x: 1.0, y: 2.0),
                          control1: CGPoint(x: 0.5, y: 0.5),
                          control2: CGPoint(x: 0.5, y: 2.0))
            path.addCurve(to: CGPoint(x: 2.0, y: 1.0),
                          control1: CGPoint(x: 1.5, y: 2.0),
                          control2: CGPoint(x: 1.5, y: 1.0))
            path.addCurve(to: CGPoint(x: 3.0, y: 3.0),
                          control1: CGPoint(x: 2.5, y: 1.0),
                          control2: CGPoint(x: 2.5, y: 2.5))
        }
        .applying(CGAffineTransform(scaleX: 6, y: -4))
        .applying(CGAffineTransform(translationX: 0, y: 18))
        context.stroke(path, with: .foreground, lineWidth: width)
    }
}
