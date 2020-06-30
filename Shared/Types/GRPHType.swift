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

extension GRPHType {
    var isTheMixed: Bool {
        self as? SimpleType == SimpleType.mixed
    }
    
    var inArray: ArrayType {
        ArrayType(content: self)
    }
    
    var optional: OptionalType {
        OptionalType(wrapped: self)
    }
    
    public static func parse(literal: String) -> GRPHType? { // needs some GRPHContext
        if literal.isSurrounded(left: "<", right: ">") {
            return parse(literal: "\(literal.dropLast().dropFirst())")
        }
        if literal.isSurrounded(left: "{", right: "}") {
            return parse(literal: "\(literal.dropLast().dropFirst())")?.inArray
        }
        if literal.hasSuffix("?") && String(literal.dropLast()).isSurrounded(left: "<", right: ">") {
            return parse(literal: String(literal.dropLast(2).dropFirst()))?.optional
        }
        if literal.contains("|") {
            let components = literal.split(separator: "|", maxSplits: 1)
            if components.count == 2 {
                let left = String(components[0])
                let right = String(components[1])
                if let type1 = parse(literal: left),
                   let type2 = parse(literal: right) {
                    return MultiOrType(type1: type1, type2: type2)
                }
            }
        }
        if literal.hasSuffix("?") {
            return parse(literal: String(literal.dropLast()))?.optional
        }
        if literal == "farray" {
            return ArrayType(content: SimpleType.float)
        }
        // TODO search types in CONTEXT aka IMPORTED
        return SimpleType.allCases.first(where: { $0.canBeCalled(literal)})
    }
}

extension String {
    func isSurrounded(left: Character, right: Character) -> Bool {
        if last == right && first == left {
            let inner = dropLast().dropFirst()
            var deepness = 0
            for char in inner {
                if char == left {
                    deepness += 1
                } else if char == right {
                    deepness -= 1
                    if deepness < 0 {
                        return false
                    }
                }
            }
            if deepness == 0 {
                return true
            }
        }
        return false
    }
}

public enum SimpleType: String, GRPHType, CaseIterable {
    
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
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let multi = other as? MultiOrType {
            return isInstance(of: multi.type1) || isInstance(of: multi.type2)
        }
        return other.isTheMixed || other as? SimpleType == self || (extending?.isInstance(of: other) ?? false)
    }
    
    public func canBeCalled(_ name: String) -> Bool {
        return name == string || aliases.contains(name)
    }
}

public struct OptionalType: GRPHType {
    var wrapped: GRPHType
    
    public var string: String {
        if wrapped is MultiOrType {
            return "<\(wrapped.string)>?"
        }
        return "\(wrapped.string)?"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        return other is OptionalType && wrapped.isInstance(of: (other as! OptionalType).wrapped)
    }
}

public struct MultiOrType: GRPHType {
    var type1, type2: GRPHType
    
    public var string: String {
        "\(type1.string)|\(type2.string)"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        return other.isTheMixed || (type1.isInstance(of: other) && type2.isInstance(of: other))
    }
}

public struct ArrayType: GRPHType {
    var content: GRPHType
    
    public var string: String {
        "{\(content.string)}"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let array = other as? ArrayType {
            return content.isInstance(of: array.content)
        }
        return other.isTheMixed
    }
}
