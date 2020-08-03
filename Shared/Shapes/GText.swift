//
//  GText.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation

class GText: PaintedShape, PositionableShape, RotatableShape {
    
    var givenName: String?
    var typeKey: String { "Text" }
    
    let uuid = UUID()
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper? = nil
    
    var font: JFont
    
    var position: Pos
    var positionZ: Int
    
    var rotation: Rotation
    var rotationCenter: Pos?
    
    init(givenName: String? = nil, position: Pos, positionZ: Int = 0, font: JFont, rotation: Rotation = 0, paint: AnyPaint) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.font = font
        self.rotation = rotation
        self.paint = paint
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Text(\(effectiveName.asLiteral)\(position.state) \(positionZ) \(font.state) \(paint.state))"
    }
    
    var type: GRPHType { SimpleType.Text }
}
