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
    
    var points: [Int] = []
    var positionZ: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var path: Path {
        Path { path in
            guard points.count >= 4 else {
                return
            }
            path.move(to: CGPoint(x: points[0], y: points[1]))
            var i = 2
            while i < points.count {
                path.addLine(to: CGPoint(x: points[i], y: points[i + 1]))
                i += 2
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
        var i = 0
        while i < points.count {
            state += " \(points[i]),\(points[i + 1])"
            i += 2
        }
        return state + ")"
    }
}
