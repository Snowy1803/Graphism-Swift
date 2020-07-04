//
//  LinearPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

struct LinearPaint: Paint, Equatable {
    var from: ColorPaint
    var direction: Direction
    var to: ColorPaint
    
    var style: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [from.style, to.style]), startPoint: direction.fromPoint, endPoint: direction.toPoint)
    }
    
    var state: String {
        "linear(\(from.state) \(direction.rawValue) \(to.state))"
    }
    
    var type: GRPHType { SimpleType.linear }
}
