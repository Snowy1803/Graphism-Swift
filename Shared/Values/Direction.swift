//
//  Direction.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

enum Direction: String, StatefulValue {
    case right, downRight, down, downLeft, left, upLeft, up, upRight
    
    var reverse: Direction {
        switch self {
        case .right:
            return .left
        case .downRight:
            return .upLeft
        case .down:
            return .up
        case .downLeft:
            return .upRight
        case .left:
            return .right
        case .upLeft:
            return .downRight
        case .up:
            return .down
        case .upRight:
            return .downLeft
        }
    }
    
    var toPoint: UnitPoint {
        switch self {
        case .right:
            return .trailing
        case .downRight:
            return .bottomTrailing
        case .down:
            return .bottom
        case .downLeft:
            return .bottomLeading
        case .left:
            return .leading
        case .upLeft:
            return .topLeading
        case .up:
            return .top
        case .upRight:
            return .topTrailing
        }
    }
    
    var fromPoint: UnitPoint {
        reverse.toPoint
    }
    
    var state: String { rawValue }
    
    var type: GRPHType { SimpleType.direction }
}
