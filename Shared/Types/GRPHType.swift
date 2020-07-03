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
    
    var staticConstants: [TypeConstant] { get }
    var fields: [Field] { get }
    
    var supertype: GRPHType { get }
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
    
    func isInstance(context: GRPHContext, expression: Expression) throws -> Bool {
        return GRPHTypes.autoboxed(type: try expression.getType(context: context, infer: self), expected: self).isInstance(of: self)
    }
    
    // default: None
    public var staticConstants: [TypeConstant] {[]}
    public var fields: [Field] {[]}
    public var supertype: GRPHType { SimpleType.mixed }
}

struct GRPHTypes {
    
    private init() {}
    
    public static func parse(context: GRPHContext, literal: String) -> GRPHType? { // needs some GRPHContext
        if literal.isSurrounded(left: "<", right: ">") {
            return parse(context: context, literal: "\(literal.dropLast().dropFirst())")
        }
        if literal.isSurrounded(left: "{", right: "}") {
            return parse(context: context, literal: "\(literal.dropLast().dropFirst())")?.inArray
        }
        if literal.hasSuffix("?") && String(literal.dropLast()).isSurrounded(left: "<", right: ">") {
            return parse(context: context, literal: String(literal.dropLast(2).dropFirst()))?.optional
        }
        if literal.contains("|") {
            let components = literal.split(separator: "|", maxSplits: 1)
            if components.count == 2 {
                let left = String(components[0])
                let right = String(components[1])
                if let type1 = parse(context: context, literal: left),
                   let type2 = parse(context: context, literal: right) {
                    return MultiOrType(type1: type1, type2: type2)
                }
            }
        }
        if literal.hasSuffix("?") {
            return parse(context: context, literal: String(literal.dropLast()))?.optional
        }
        if literal == "farray" {
            return ArrayType(content: SimpleType.float)
        }
        // TODO search types in CONTEXT aka IMPORTED
        return SimpleType.allCases.first(where: { $0.canBeCalled(literal)})
    }
    
    /// Type of a value is calculated HERE
    /// It uses GRPHValue.type but takes into account AUTOBOXING and AUTOUNBOXING, based on expected.
    /// Also, type of null is inferred here
    public static func type(of value: GRPHValue, expected: GRPHType? = nil) -> GRPHType {
        return autoboxed(type: realType(of: value, expected: expected), expected: expected)
    }
    
    public static func autoboxed(type: GRPHType, expected: GRPHType?) -> GRPHType {
        if !(type is OptionalType),
           let expected = expected as? OptionalType { // Boxing
            return OptionalType(wrapped: autoboxed(type: type, expected: expected.wrapped))
        } else if let type = type as? OptionalType,
                  let expected = expected as? OptionalType { // Recursive, multi? optional
            return OptionalType(wrapped: autoboxed(type: type.wrapped, expected: expected.wrapped))
        } else if let type = type as? OptionalType { // Unboxing
            return autoboxed(type: type.wrapped, expected: expected)
        }
        return type
    }
    
    public static func autobox(value: GRPHValue, expected: GRPHType) throws -> GRPHValue {
        if let value = value as? GRPHOptional {
            if let expected = expected as? OptionalType { // recursive
                switch value {
                case .null:
                    return value
                case .some(let wrapped):
                    return GRPHOptional.some(try autobox(value: wrapped, expected: expected.wrapped))
                }
            } else { // Unboxing
                switch value {
                case .null:
                    throw GRPHCompileError(type: .typeMismatch, message: "Tried to auto-unbox a 'null' value") // TODO RUNTIME ERROR
                case .some(let wrapped):
                    return try autobox(value: wrapped, expected: expected) // Unboxing
                }
            }
        } else if let expected = expected as? OptionalType { // Boxing
            return GRPHOptional.some(try autobox(value: value, expected: expected.wrapped))
        } else {
            return value
        }
    }
    
    public static func realType(of value: GRPHValue, expected: GRPHType?) -> GRPHType {
        if let value = value as? GRPHOptional,
           value.isEmpty,
           expected is OptionalType {
            return expected ?? OptionalType(wrapped: SimpleType.mixed)
        }
        return value.type
    }
    
    public static func field(named name: String, in type: GRPHType) -> Field? {
        if let property = type.fields.first(where: { $0.name == name }) {
            return property
        }
        if type.isTheMixed {
            return nil
        }
        return field(named: name, in: type.supertype)
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
    
    // MISSING = font, Text, Group, Background
    
    public var string: String {
        rawValue
    }
    
    public var supertype: GRPHType {
        return extending ?? SimpleType.mixed
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
    
    public var staticConstants: [TypeConstant] {
        switch self {
        case .color:
            return [TypeConstant(name: "WHITE", type: self, value: ColorPaint.white),
                    TypeConstant(name: "LIGHT_GRAY", type: self, value: ColorPaint.components(red: 0.75, green: 0.75, blue: 0.75)),
                    TypeConstant(name: "GRAY", type: self, value: ColorPaint.components(red: 0.5, green: 0.5, blue: 0.5)),
                    TypeConstant(name: "DARK_GRAY", type: self, value: ColorPaint.components(red: 0.25, green: 0.25, blue: 0.25)),
                    TypeConstant(name: "BLACK", type: self, value: ColorPaint.black),
                    TypeConstant(name: "RED", type: self, value: ColorPaint.red),
                    TypeConstant(name: "GREEN", type: self, value: ColorPaint.green),
                    TypeConstant(name: "BLUE", type: self, value: ColorPaint.blue),
                    TypeConstant(name: "CYAN", type: self, value: ColorPaint.components(red: 0, green: 1, blue: 1)),
                    TypeConstant(name: "MAGENTA", type: self, value: ColorPaint.components(red: 1, green: 0, blue: 1)),
                    TypeConstant(name: "YELLOW", type: self, value: ColorPaint.components(red: 1, green: 1, blue: 0)),
                    TypeConstant(name: "ORANGE", type: self, value: ColorPaint.orange),
                    TypeConstant(name: "BROWN", type: self, value: ColorPaint.components(red: 0.6, green: 0.2, blue: 0)),
                    TypeConstant(name: "PURPLE", type: self, value: ColorPaint.purple), // Not in Java?
                    TypeConstant(name: "PINK", type: self, value: ColorPaint.pink),
                    TypeConstant(name: "ALPHA", type: self, value: ColorPaint.alpha)]
        case .float:
            return [TypeConstant(name: "POSITIVE_INFINITY", type: self, value: Float.infinity),
                    TypeConstant(name: "NEGATIVE_INFINITY", type: self, value: -Float.infinity),
                    TypeConstant(name: "NOT_A_NUMBER", type: self, value: Float.nan)]
        case .integer:
            return [TypeConstant(name: "MAX", type: self, value: Int.max),
                    TypeConstant(name: "MIN", type: self, value: Int.min)]
        case .font:
            return [] // TODO
        case .pos:
            return [TypeConstant(name: "ORIGIN", type: self, value: Pos(x: 0, y: 0))]
        case .stroke:
            return [TypeConstant(name: "ELONGATED", type: self, value: Stroke.elongated),
                    TypeConstant(name: "CUT", type: self, value: Stroke.cut),
                    TypeConstant(name: "ROUNDED", type: self, value: Stroke.rounded)]
        case .direction:
            return [TypeConstant(name: "RIGHT", type: self, value: Direction.right),
                    TypeConstant(name: "DOWN_RIGHT", type: self, value: Direction.downRight),
                    TypeConstant(name: "DOWN", type: self, value: Direction.down),
                    TypeConstant(name: "DOWN_LEFT", type: self, value: Direction.downLeft),
                    TypeConstant(name: "LEFT", type: self, value: Direction.left),
                    TypeConstant(name: "UP_LEFT", type: self, value: Direction.upLeft),
                    TypeConstant(name: "UP", type: self, value: Direction.up),
                    TypeConstant(name: "UP_RIGHT", type: self, value: Direction.upRight)]
        default:
            return []
        }
    }
    
    public var fields: [Field] {
        switch self {
        case .pos:
            return [KeyPathField(name: "x", type: SimpleType.float, keyPath: \Pos.x),
                    KeyPathField(name: "y", type: SimpleType.float, keyPath: \Pos.y)]
        case .color:
            return [VirtualField<ColorPaint>(name: "red", type: SimpleType.integer, getter: { Int(($0.rgba?.red ?? -1) * 255) }),
                    VirtualField<ColorPaint>(name: "green", type: SimpleType.integer, getter: { Int(($0.rgba?.green ?? -1) * 255) }),
                    VirtualField<ColorPaint>(name: "blue", type: SimpleType.integer, getter: { Int(($0.rgba?.blue ?? -1) * 255) }),
                    VirtualField<ColorPaint>(name: "alpha", type: SimpleType.integer, getter: { Int(($0.rgba?.alpha ?? -1) * 255) }),
                    VirtualField<ColorPaint>(name: "fred", type: SimpleType.integer, getter: { $0.rgba?.red ?? -1 }),
                    VirtualField<ColorPaint>(name: "fgreen", type: SimpleType.integer, getter: { $0.rgba?.green ?? -1 }),
                    VirtualField<ColorPaint>(name: "fblue", type: SimpleType.integer, getter: { $0.rgba?.blue ?? -1 }),
                    VirtualField<ColorPaint>(name: "falpha", type: SimpleType.integer, getter: { $0.rgba?.alpha ?? -1 })]
        case .linear:
            return [KeyPathField(name: "fromColor", type: SimpleType.color, keyPath: \LinearPaint.from),
                    KeyPathField(name: "toColor", type: SimpleType.color, keyPath: \LinearPaint.to),
                    KeyPathField(name: "direction", type: SimpleType.direction, keyPath: \LinearPaint.direction)]
            // uhm they are structs, not writeable on java edition, here they are writeable, but they would be value types? Depends on assignment implementation
        case .radial:
            return [KeyPathField(name: "fromColor", type: SimpleType.color, keyPath: \RadialPaint.centerColor),
                    KeyPathField(name: "toColor", type: SimpleType.color, keyPath: \RadialPaint.externalColor),
                    KeyPathField(name: "center", type: SimpleType.pos, keyPath: \RadialPaint.center),
                    KeyPathField(name: "radius", type: SimpleType.float, keyPath: \RadialPaint.radius)]
            // same as above
        // fonts & images
        case .rotation:
            return [KeyPathField(name: "value", type: SimpleType.integer, keyPath: \Rotation.value)]
            // same as above
        case .string:
            return [VirtualField<String>(name: "length", type: SimpleType.integer, getter: { $0.count })]
        case .shape:
            return [ErasedField(name: "name", type: SimpleType.string, getter: { ($0 as! GShape).effectiveName }, setter: {
                var shape = ($0 as! GShape)
                shape.effectiveName = $1 as! String // shapes are always reference types
            }),
            ErasedField(name: "location", type: SimpleType.pos, getter: { ($0 as? BasicShape)?.position ?? Pos(x: 0, y: 0) }, setter: {
                if var shape = ($0 as? BasicShape) {
                    shape.position = $1 as! Pos
                } else {
                    // throw runtime error
                }
            }),] // TODO etc
        default:
            return []
        }
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
    
    public var fields: [Field] {
        return [VirtualField<GRPHArray>(name: "length", type: SimpleType.integer, getter: { $0.count })]
    }
}
