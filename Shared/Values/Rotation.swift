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
        self.init(value: value)
    }
    
    init(value: Int) {
        // Normalize: -180 < value ≤ 180
        self.value = value % 360
        if self.value <= -180 {
            self.value += 360
        }
        if self.value > 180 {
            self.value -= 360
        }
    }
    
    init?(byCasting value: GRPHValue) {
        if let value = value as? Int {
            self.init(value: value)
            return
        } else if let value = value as? Float {
            self.init(value: Int(value))
            return
        } else if let value = value as? String {
            if value.hasSuffix("º") || value.hasSuffix("°") {
                if let i = Int(decoding: value.dropLast()) {
                    self.init(value: i)
                    return
                }
            } else if let i = Int(decoding: value) {
                self.init(value: i)
                return
            }
        }
        return nil
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
