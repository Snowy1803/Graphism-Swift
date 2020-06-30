//
//  ColorPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

public enum ColorPaint: Paint {
    case wrapping(Color)
    
    case components(red: Float, green: Float, blue: Float, alpha: Float = 1)
    
    public var style: Color {
        switch self {
        case .wrapping(let color):
            return color
        case .components(red: let red, green: let green, blue: let blue, alpha: let alpha):
            return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
        }
    }
    
    public var state: String {
        switch self {
        case .wrapping(let color):
            return color.description.uppercased()
        case .components(red: let red, green: let green, blue: let blue, alpha: let alpha):
            return "color(\(red) \(green) \(blue) \(alpha))"
        }
    }
    
    public var type: GRPHType { SimpleType.color }
}
