//
//  ColorPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation
import SwiftUI

public enum ColorPaint: Paint {
    case white, black, red, green, blue, orange, yellow, pink, purple, aqua, alpha
    
    case components(red: Float, green: Float, blue: Float, alpha: Float = 1)
    
    public var style: Color {
        switch self {
        case .components(red: let red, green: let green, blue: let blue, alpha: let alpha):
            return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
        case .white:
            return .white
        case .black:
            return .black
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .pink:
            return .pink
        case .purple:
            return .purple
        case .aqua:
            return .init(red: 0, green: 0.85, blue: 0.85)
        case .alpha:
            return .clear
        }
    }
    
    public var state: String {
        switch self {
        case .components(red: let red, green: let green, blue: let blue, alpha: let alpha):
            return "color(\(red) \(green) \(blue) \(alpha))"
        case .white:
            return "WHITE"
        case .black:
            return "BLACK"
        case .red:
            return "RED"
        case .green:
            return "GREEN"
        case .blue:
            return "BLUE"
        case .orange:
            return "ORANGE"
        case .yellow:
            return "YELLOW"
        case .pink:
            return "PINK"
        case .purple:
            return "PURPLE"
        case .aqua:
            return "AQUA"
        case .alpha:
            return "ALPHA"
        }
    }
    
    public var type: GRPHType { SimpleType.color }
}
