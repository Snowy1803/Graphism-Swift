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
    
    var start: Pos
    var end: Pos
    var positionZ: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var path: Path {
        Path { path in
            path.move(to: start.cg)
            path.addLine(to: end.cg)
        }
    }
    
    var graphics: AnyView {
        path.stroke(paint, style: strokeStyle ?? StrokeStyle(lineWidth: 5))
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Line(\(givenName?.asLiteral ?? "")\(start.state) \(end.state) \(positionZ) \(paint.description.uppercased())\(strokeStyle?.stateConstructor ?? ""))"
    }
}
