//
//  Rotation.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

struct Rotation: StatefulValue, ExpressibleByIntegerLiteral, Equatable {
    var value: Int
    
    var state: String {
        "\(value)°"
    }
    
    init(integerLiteral value: Int) {
        self.value = value
    }
    
    init(value: Int) {
        self.value = value
    }
    
    var angle: Angle {
        .degrees(Double(value))
    }
    
    var type: GRPHType { SimpleType.rotation }
    
    static func + (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(value: lhs.value + rhs.value)
    }
    
    static func - (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(value: lhs.value - rhs.value)
    }
}
