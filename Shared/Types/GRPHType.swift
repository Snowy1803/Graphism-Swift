//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

protocol GRPHType: CustomStringConvertible, Importable {
    var string: String { get }
    
    func isInstance(of other: GRPHType) -> Bool
    
    var staticConstants: [TypeConstant] { get }
    var fields: [Field] { get }
    var constructor: Constructor? { get }
    
    var supertype: GRPHType { get }
    var final: Bool { get }
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
    var staticConstants: [TypeConstant] {[]}
    var fields: [Field] {[]}
    var supertype: GRPHType { SimpleType.mixed }
    var final: Bool { false }
    var constructor: Constructor? { nil }
    
    var description: String {
        string
    }
    
    var exportedTypes: [GRPHType] { [self] }
}

struct GRPHTypes {
    
    private init() {}
    
    static func parse(context: GRPHContext, literal: String) -> GRPHType? { // needs some GRPHContext
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
        if let found = (context.compiler?.imports ?? NameSpaces.instances).flatMap({ $0.exportedTypes }).first(where: { $0.string == literal }) {
            return found
        }
        return (context.compiler?.imports ?? NameSpaces.instances).flatMap({ $0.exportedTypeAliases }).first(where: { $0.name == literal })?.type
    }
    
    /// Type of a value is calculated HERE
    /// It uses GRPHValue.type but takes into account AUTOBOXING and AUTOUNBOXING, based on expected.
    /// Also, type of null is inferred here
    static func type(of value: GRPHValue, expected: GRPHType? = nil) -> GRPHType {
        return autoboxed(type: realType(of: value, expected: expected), expected: expected)
    }
    
    static func autoboxed(type: GRPHType, expected: GRPHType?) -> GRPHType {
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
    
    static func autobox(value: GRPHValue, expected: GRPHType) throws -> GRPHValue {
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
                    throw GRPHRuntimeError(type: .cast, message: "Tried to auto-unbox a 'null' value")
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
    
    /// Use this instead of autobox if you always expect an unwrapped value, as it's faster
    static func unbox(value: GRPHValue) throws -> GRPHValue {
        if let value = value as? GRPHOptional {
            switch value {
            case .null:
                throw GRPHRuntimeError(type: .typeMismatch, message: "Tried to auto-unbox a 'null' value")
            case .some(let wrapped):
                return try unbox(value: wrapped) // Unboxing
            }
        } else {
            return value
        }
    }
    
    static func realType(of value: GRPHValue, expected: GRPHType?) -> GRPHType {
        if let value = value as? GRPHOptional,
           value.isEmpty,
           expected is OptionalType {
            return expected ?? OptionalType(wrapped: SimpleType.mixed)
        }
        return value.type
    }
    
    static func field(named name: String, in type: GRPHType) -> Field? {
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
