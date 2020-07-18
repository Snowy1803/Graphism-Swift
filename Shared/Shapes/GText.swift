//
//  GText.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation
import SwiftUI

class GText: SimpleShape, BasicShape {
    
    var givenName: String?
    var typeKey: String { "Text" }
    
    let uuid = UUID()
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper? = nil
    
    var font: JFont
    
    var position: Pos
    var positionZ: Int
    
    init(givenName: String? = nil, position: Pos, positionZ: Int = 0, font: JFont, paint: AnyPaint) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.font = font
        self.paint = paint
    }
    
    var uiText: Text {
        font.apply(Text(effectiveName))
    }
    
    var modifiedText: AnyView {
        switch paint {
        case .color(let c):
            return uiText.foregroundColor(c.style).erased
        case .linear(let l):
            return l.style.mask(uiText).erased
        case .radial(let r):
            return r.style.mask(uiText).erased
        }
    }
    
    var graphics: AnyView {
        modifiedText
            .position(position.cg)
            .erased
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Text(\(effectiveName.asLiteral)\(position.state) \(positionZ) \(font.state) \(paint.state))"
    }
    
    var type: GRPHType { SimpleType.Text }
}
