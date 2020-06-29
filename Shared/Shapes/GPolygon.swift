//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


struct GPolygon: SimpleShape { // Add rotation support
    var givenName: String?
    var typeKey: String { "Polygon" }
    
    var uuid = UUID()
    
    var points: [Pos] = []
    var positionZ: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var path: Path {
        Path { path in
            guard points.count >= 2 else {
                return
            }
            path.move(to: points[0].cg)
            for point in points {
                path.addLine(to: point.cg)
            }
            path.closeSubpath()
        }
    }
    
    var graphics: AnyView {
        path.applyingFillOrStroke(for: self)
            .erased
    }
    
    var stateDefinitions: String { "" }
    
    var stateConstructor: String {
        var state = "Polygon(\(givenName?.asLiteral ?? "")\(positionZ) \(paint.description.uppercased())\(strokeStyle?.stateConstructor ?? "")"
        for point in points {
            state += " \(point.state)"
        }
        return state + ")"
    }
}
