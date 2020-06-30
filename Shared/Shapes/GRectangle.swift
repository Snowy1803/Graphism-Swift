//
//  GRectangle.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


class GRectangle: RectangularShape, SimpleShape, RotatableShape {
    
    var givenName: String?
    var typeKey: String { size.square ? "Square" : "Rectangle" }
    
    var uuid = UUID()
    
    var position: Pos
    var positionZ: Int = 0
    var size: Pos
    var rotation: Rotation = 0
    
    var paint: AnyPaint
    var strokeStyle: StrokeStyle?
    
    init(givenName: String? = nil, position: Pos, positionZ: Int = 0, size: Pos, rotation: Rotation = 0, paint: AnyPaint, strokeStyle: StrokeStyle? = nil) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.size = size
        self.rotation = rotation
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    var graphics: AnyView {
        Rectangle()
            .applyingFillOrStroke(for: self)
            .frame(width: CGFloat(size.x), height: CGFloat(size.y))
            .rotationEffect(rotation.angle, anchor: .center) // TODO support for rotationCenter
            .position(center.cg)
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Rectangle(\(givenName?.asLiteral ?? "")\(position.state) \(positionZ) \(size.state) \(rotation.state) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
}
