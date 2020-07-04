//
//  RadialPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

struct RadialPaint: Paint, Equatable {
    var centerColor: ColorPaint
    var center: Pos = Pos(x: 0.5, y: 0.5)// Unit coordinates (0-1)
    var externalColor: ColorPaint
    var radius: Float // Radius is real coordinates, unlike Java version :/
    // Does not support focus :(
    
    var style: RadialGradient {
        RadialGradient(gradient: Gradient(colors: [centerColor.style, externalColor.style]), center: .init(x: center.cg.x, y: center.cg.y), startRadius: 0, endRadius: CGFloat(radius))
    }
    
    var state: String {
        "radial(\(centerColor.state) \(center.state) \(externalColor.state) \(radius))"
    }
    
    var type: GRPHType { SimpleType.radial }
}
