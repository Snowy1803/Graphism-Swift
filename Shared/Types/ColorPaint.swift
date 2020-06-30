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
    
    case components(red: Int, green: Int, blue: Int, alpha: Int = 255)
    
    public var style: Color {
        switch self {
        case .wrapping(let color):
            return color
        case .components(red: let red, green: let green, blue: let blue, alpha: let alpha):
            return Color(red: Double(red)/255.0, green: Double(green)/255.0, blue: Double(blue)/255.0, opacity: Double(alpha)/255.0)
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
}
