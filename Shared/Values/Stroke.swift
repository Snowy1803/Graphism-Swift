//
//  Stroke.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

enum Stroke: String, StatefulValue {
    case elongated, cut, rounded
    
    var state: String { rawValue }
    
    var type: GRPHType { SimpleType.stroke }
}


struct StrokeWrapper {
    var strokeWidth: Float = 5
    var strokeType: Stroke = .cut
    var strokeDashArray: GRPHArray = GRPHArray(of: SimpleType.float)
    
    var stateConstructor: String {
        " \(strokeWidth) \(strokeType.rawValue) \(strokeDashArray.state)"
    }
}
