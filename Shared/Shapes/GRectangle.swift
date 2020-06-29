//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


struct GRectangle: RectangularShape, SimpleShape, RotableShape {
    var givenName: String?
    var typeKey: String { "Rectangle" }
    
    var uuid = UUID()
    
    var positionX: Int
    var positionY: Int
    var positionZ: Int = 0
    var sizeX: Int
    var sizeY: Int
    var rotation: Int = 0
    
    var paint: Color
    
    var graphics: AnyView {
        Rectangle()
            .fill(paint)
            .frame(width: CGFloat(sizeX), height: CGFloat(sizeY))
            .rotationEffect(.degrees(Double(rotation)), anchor: .center) // TODO support for rotationCenter
            .position(x: CGFloat(centerX), y: CGFloat(centerY))
            .erased
    }
    
    var stateConstructor: String {
        "Rectangle(\(givenName?.asLiteral ?? "")\(positionX),\(positionY) \(positionZ) \(sizeX),\(sizeY) \(rotation)º \(paint.description.uppercased()))"
    }
}
