//
//  GImage.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation
import SwiftUI

class GImage {
    var shapes: [GShape] = []
    var size: Pos = Pos(x: 640, y: 480)
    var background: AnyPaint = AnyPaint.color(ColorPaint.alpha)
    
    var graphics: AnyView {
        ZStack(alignment: .topLeading) {
            ForEach(shapes, id: \.uuid) { shape in
                shape.graphics
            }
        }.erased
    }
}
