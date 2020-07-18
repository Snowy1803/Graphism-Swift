//
//  GPolygon.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

class GPolygon: SimpleShape { // Add rotation support
    var givenName: String?
    var typeKey: String { "Polygon" }
    
    let uuid = UUID()
    
    var points: [Pos] = []
    var positionZ: Int = 0
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper?
    
    init(givenName: String? = nil, points: [Pos] = [], positionZ: Int = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.points = points
        self.positionZ = positionZ
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    var stateDefinitions: String { "" }
    
    var stateConstructor: String {
        var state = "Polygon(\(givenName?.asLiteral ?? "")\(positionZ) \(paint.state)\(strokeStyle?.stateConstructor ?? "")"
        for point in points {
            state += " \(point.state)"
        }
        return state + ")"
    }
    
    var type: GRPHType { SimpleType.Polygon }
}
