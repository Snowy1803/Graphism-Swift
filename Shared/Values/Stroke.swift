//
//  Stroke.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

enum Stroke: String, StatefulValue {
    case elongated, cut, rounded
    
    var lineCap: CGLineCap {
        switch self {
        case .elongated:
            return .square
        case .cut:
            return .butt
        case .rounded:
            return .round
        }
    }
    
    var lineJoin: CGLineJoin {
        switch self {
        case .elongated:
            return .miter
        case .cut:
            return .bevel
        case .rounded:
            return .round
        }
    }
    
    var state: String { rawValue }
    
    var type: GRPHType { SimpleType.stroke }
}


struct StrokeWrapper {
    var strokeWidth: Float = 5
    var strokeType: Stroke = .cut
    var strokeDashArray: GRPHArray = GRPHArray(of: SimpleType.float)
    
    var cg: StrokeStyle {
        StrokeStyle(lineWidth: CGFloat(strokeWidth), lineCap: strokeType.lineCap, lineJoin: strokeType.lineJoin, miterLimit: 10, dash: strokeDashArray.wrapped.map { CGFloat($0 as! Float) }, dashPhase: 0)
    }
    
    var stateConstructor: String {
        " \(strokeWidth) \(strokeType.rawValue) \(strokeDashArray.state)"
    }
}
