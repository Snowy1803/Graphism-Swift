//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


struct GLine: SimpleShape {
    var givenName: String?
    var typeKey: String { "Line" }
    
    var uuid = UUID()
    
    var startX: Int
    var startY: Int
    var endX: Int
    var endY: Int
    var positionZ: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var path: Path {
        Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
    }
    
    var graphics: AnyView {
        path.stroke(paint, style: strokeStyle ?? StrokeStyle(lineWidth: 5))
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Line(\(givenName?.asLiteral ?? "")\(startX),\(startY) \(endX),\(endY) \(positionZ) \(paint.description.uppercased())\(strokeStyle?.stateConstructor ?? ""))"
    }
}
