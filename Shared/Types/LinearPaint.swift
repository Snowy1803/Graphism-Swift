//
//  LinearPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

public struct LinearPaint: Paint, Equatable {
    var from: ColorPaint
    var direction: Direction
    var to: ColorPaint
    
    public var style: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [from.style, to.style]), startPoint: direction.fromPoint, endPoint: direction.toPoint)
    }
    
    public var state: String {
        "linear(\(from.state) \(direction.rawValue) \(to.state))"
    }
    
    public var type: GRPHType { SimpleType.linear }
}
