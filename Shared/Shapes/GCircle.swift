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
    var typeKey: String { "Ellipse" }
    
    var uuid = UUID()
    
    var positionX: Int
    var positionY: Int
    var positionZ: Int = 0
    var sizeX: Int
    var sizeY: Int
    var rotation: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var graphics: AnyView {
        Ellipse()
            .applyingFillOrStroke(for: self)
            .frame(width: CGFloat(sizeX), height: CGFloat(sizeY))
            .rotationEffect(.degrees(Double(rotation)), anchor: .center) // TODO support for rotationCenter
            .position(x: CGFloat(centerX), y: CGFloat(centerY))
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Ellipse(\(givenName?.asLiteral ?? "")\(positionX),\(positionY) \(positionZ) \(sizeX),\(sizeY) \(rotation)° \(paint.description.uppercased())\(strokeStyle?.stateConstructor ?? ""))"
    }
}
