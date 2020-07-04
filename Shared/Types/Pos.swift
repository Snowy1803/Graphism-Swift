//
//  Pos.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import CoreGraphics

public struct Pos: StatefulValue, Equatable {
    var x: Float
    var y: Float
    
    public var state: String {
        "\(x),\(y)"
    }
    
    var square: Bool {
        x == y
    }
    
    var cg: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    public var type: GRPHType { SimpleType.pos }
}
