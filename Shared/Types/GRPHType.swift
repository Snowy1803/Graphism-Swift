//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public protocol GRPHType {
    var string: String { get }
    
    func isInstance(of other: GRPHType) -> Bool
}

public enum SimpleType: String, GRPHType {
    
    case num, integer, float, rotation, pos, boolean, string, paint, color, linear, radial, shape, direction, stroke, /*file, image,*/ font, mixed
    
    case Rectangle, Circle, Line, Polygon, /*Image,*/ Text, Path, Group, Background
    
    // MISSING = stroke, font, Text, Group, Background
    
    public var string: String {
        rawValue
    }
    
    var extending: SimpleType? {
        switch self {
        case .integer, .float:
            return .num
        case .color, .linear, .radial:
            return .paint
        case .Rectangle, .Circle, .Line, .Polygon, .Text, .Path, .Group:
            return .shape // Image --> Rectangle
        case .Background:
            return .Group
        default:
            return nil
        }
    }
    
    var aliases: [String] {
        switch self {
        case .integer:
            return ["int"]
        // image --> "texture"
        case .Rectangle:
            return ["Square", "Rect", "R"]
        case .Circle:
            return ["Ellipse", "E", "C"]
        case .Line:
            return ["L"]
        case .Polygon:
            return ["Poly", "P"]
        // Image --> "Img", "I", "Sprite"
        case .Text:
            return ["T"]
        case .Group:
            return ["G"]
        case .Background:
            return ["Back"]
        default:
            return []
        }
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        return other as? SimpleType == SimpleType.mixed || other as? SimpleType == self || (extending?.isInstance(of: other) ?? false)
    }
}
