//
//  GText.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation

class GText: SimpleShape, BasicShape {
    
    var givenName: String?
    var typeKey: String { "Text" }
    
    let uuid = UUID()
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper? = nil
    
    var font: JFont
    
    // Here in Swift Edition, it is the center. On Java Graphism, its the leading point.
    var position: Pos
    var positionZ: Int
    
    init(givenName: String? = nil, position: Pos, positionZ: Int = 0, font: JFont, paint: AnyPaint) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.font = font
        self.paint = paint
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Text(\(effectiveName.asLiteral)\(position.state) \(positionZ) \(font.state) \(paint.state))"
    }
    
    var type: GRPHType { SimpleType.Text }
}
