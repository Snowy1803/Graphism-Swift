//
//  ColorPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

enum ColorPaint: Paint, Equatable {
    case white, black, red, green, blue, orange, yellow, pink, purple, aqua, alpha
    
    case components(red: Float, green: Float, blue: Float, alpha: Float = 1)
    
    var state: String {
        switch self {
        case .components(red: _, green: _, blue: _, alpha: let alpha):
            return "color(\(grphRed) \(grphGreen) \(grphBlue) \(alpha))"
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
    
    var rgba: (red: Float, green: Float, blue: Float, alpha: Float)? {
        switch self {
        case let .components(red: r, green: g, blue: b, alpha: a):
            return (red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }
    
    var type: GRPHType { SimpleType.color }
}

extension ColorPaint {
    var grphRed: Int {
        get {
            Int((rgba?.red ?? -1) * 255)
        }
        set {
            if case let .components(_, green, blue, alpha) = self {
                self = .components(red: Float(newValue) / 255, green: green, blue: blue, alpha: alpha)
            }
        }
    }
    var grphGreen: Int {
        get {
            Int((rgba?.green ?? -1) * 255)
        }
        set {
            if case let .components(red, _, blue, alpha) = self {
                self = .components(red: red, green: Float(newValue) / 255, blue: blue, alpha: alpha)
            }
        }
    }
    var grphBlue: Int {
        get {
            Int((rgba?.blue ?? -1) * 255)
        }
        set {
            if case let .components(red, green, _, alpha) = self {
                self = .components(red: red, green: green, blue: Float(newValue) / 255, alpha: alpha)
            }
        }
    }
    var grphAlpha: Int {
        get {
            Int((rgba?.alpha ?? -1) * 255)
        }
        set {
            if case let .components(red, green, blue, _) = self {
                self = .components(red: red, green: green, blue: blue, alpha: Float(newValue) / 255)
            }
        }
    }
    var grphFRed: Float {
        get {
            rgba?.red ?? -1
        }
        set {
            if case let .components(_, green, blue, alpha) = self {
                self = .components(red: newValue, green: green, blue: blue, alpha: alpha)
            }
        }
    }
    var grphFGreen: Float {
        get {
            rgba?.green ?? -1
        }
        set {
            if case let .components(red, _, blue, alpha) = self {
                self = .components(red: red, green: newValue, blue: blue, alpha: alpha)
            }
        }
    }
    var grphFBlue: Float {
        get {
            rgba?.blue ?? -1
        }
        set {
            if case let .components(red, green, _, alpha) = self {
                self = .components(red: red, green: green, blue: newValue, alpha: alpha)
            }
        }
    }
    var grphFAlpha: Float {
        get {
            rgba?.alpha ?? -1
        }
        set {
            if case let .components(red, green, blue, _) = self {
                self = .components(red: red, green: green, blue: blue, alpha: newValue)
            }
        }
    }
    
    init(integer value: Int, alpha: Bool) {
         self = .components(red: Float((value >> 16) & 0xFF) / 255,
                                     green: Float((value >> 8) & 0xFF) / 255,
                                     blue: Float(value & 0xFF) / 255,
                                     alpha: alpha ? Float((value >> 24) & 0xFF) / 255 : 1)
    }
    
    var svgColor: String {
        "rgba(\(grphRed), \(grphGreen), \(grphBlue), \(grphFAlpha))"
    }
}
