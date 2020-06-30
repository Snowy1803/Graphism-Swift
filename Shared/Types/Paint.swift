//
//  Paint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

public protocol Paint: GRPHValue {
    
    associatedtype Style: ShapeStyle
    
    var style: Style { get }
    
    var state: String { get }
}

public enum AnyPaint {
    case color(ColorPaint)
    case linear(LinearPaint)
    case radial(RadialPaint)
    
    var state: String {
        switch self {
        case .color(let color):
            return color.state
        case .linear(let linear):
            return linear.state
        case .radial(let radial):
            return radial.state
        }
    }
}
