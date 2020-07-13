//
//  Pos.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import CoreGraphics

struct Pos: StatefulValue, Equatable {
    var x: Float
    var y: Float
    
    var state: String {
        "\(x),\(y)"
    }
    
    var square: Bool {
        x == y
    }
    
    var cg: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    var type: GRPHType { SimpleType.pos }
    
    static func + (lhs: Pos, rhs: Pos) -> Pos {
        Pos(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
