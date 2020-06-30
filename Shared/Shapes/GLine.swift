//
//  GLine.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


class GLine: SimpleShape {
    var givenName: String?
    var typeKey: String { "Line" }
    
    var uuid = UUID()
    
    var start: Pos
    var end: Pos
    var positionZ: Int = 0
    
    var paint: AnyPaint
    var strokeStyle: StrokeStyle?
    
    init(givenName: String? = nil, start: Pos, end: Pos, positionZ: Int = 0, paint: AnyPaint, strokeStyle: StrokeStyle? = nil) {
        self.givenName = givenName
        self.start = start
        self.end = end
        self.positionZ = positionZ
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    var path: Path {
        Path { path in
            path.move(to: start.cg)
            path.addLine(to: end.cg)
        }
    }
    
    var graphics: AnyView {
        path.applyingStroke(strokeStyle ?? StrokeStyle(lineWidth: 5), paint: paint)
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Line(\(givenName?.asLiteral ?? "")\(start.state) \(end.state) \(positionZ) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
}
