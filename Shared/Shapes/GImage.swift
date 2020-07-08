//
//  GImage.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation
import SwiftUI

class GImage: GGroup {
    var size: Pos = Pos(x: 640, y: 480)
    var background: AnyPaint = AnyPaint.color(ColorPaint.alpha)
    
    init(size: Pos = Pos(x: 640, y: 480), background: AnyPaint = AnyPaint.color(ColorPaint.alpha)) {
        self.size = size
        self.background = background
    }
    
    override var typeKey: String {
        "Background"
    }
    
    override var type: GRPHType {
        SimpleType.Background
    }
    
    override var stateDefinitions: String {
        "" // never called
    }
    
    override var stateConstructor: String {
        "Background(\(size.state) \(background.state))"
    }
}
