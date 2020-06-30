//
//  Rotation.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

public struct Rotation: StatefulValue, ExpressibleByIntegerLiteral {
    var value: Int
    
    public var state: String {
        "\(value)°"
    }
    
    public init(integerLiteral value: Int) {
        self.value = value
    }
    
    init(value: Int) {
        self.value = value
    }
    
    var angle: Angle {
        .degrees(Double(value))
    }
    
    public var type: GRPHType { SimpleType.rotation }
}
