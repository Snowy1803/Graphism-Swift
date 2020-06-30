//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


struct GCircle: RectangularShape, SimpleShape, RotableShape {
    var givenName: String?
    var typeKey: String { size.square ? "Circle" : "Ellipse" }
    
    var uuid = UUID()
    
    var position: Pos
    var positionZ: Int = 0
    var size: Pos
    var rotation: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var graphics: AnyView {
        Ellipse()
            .applyingFillOrStroke(for: self)
            .frame(width: CGFloat(size.x), height: CGFloat(size.y))
            .rotationEffect(.degrees(Double(rotation)), anchor: .center) // TODO support for rotationCenter
            .position(center.cg)
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Ellipse(\(givenName?.asLiteral ?? "")\(position.state) \(positionZ) \(size.state) \(rotation)° \(paint.description.uppercased())\(strokeStyle?.stateConstructor ?? ""))"
    }
}
