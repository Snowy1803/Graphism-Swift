//
//  CastExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct CastExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.+) (is|as\\??!?) (\(Expressions.typePattern))$")
    
    var from: Expression
    var cast: CastType
    var to: GRPHType
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        let raw = try from.eval(context: context)
        if case .typeCheck = cast {
            return GRPHTypes.type(of: raw).isInstance(of: to) // no autoboxing in is
        }
        let value = try GRPHTypes.autobox(value: raw, expected: to)
        if case .strict(optional: _) = cast {
            if GRPHTypes.type(of: value).isInstance(of: to) {
                return wrap(value)
            }
        } else {
            // boxing, unboxing and all null values returns here
            if GRPHTypes.type(of: value).isInstance(of: to) {
                return wrap(value)
            }
            if let result = CastExpression.cast(value: value, to: to) {
                return wrap(result)
            }
        }
        if cast.optional {
            return GRPHOptional.null
        }
        throw GRPHRuntimeError(type: .cast, message: "Couldn't cast from \(GRPHTypes.type(of: value)) to \(to)")
    }
    
    @inlinable func wrap(_ value: GRPHValue) -> GRPHValue {
        cast.optional ? GRPHOptional(value) : value
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        if case .typeCheck = cast {
            return SimpleType.boolean
        } else if cast.optional {
            return to.optional
        } else {
            return to
        }
    }
    
    var string: String { "\(from.string) \(cast.string) \(to.string)" }
    
    var needsBrackets: Bool { true }
    
    /// value must already be autoboxed, and null must already be taken care of. NO NULL HERE
    /// Returns nil if the cast didn't succeed
    static func cast(value: GRPHValue, to: GRPHType) -> GRPHValue? {
        if let to = to as? OptionalType,
           let value = value as? GRPHOptional {
            if let inner = cast(value: value.content!, to: to.wrapped) {
                return GRPHOptional(inner)
            }
            return nil
        }
        if let to = to as? SimpleType {
            switch to {
            case .num:
                if let value = value as? Int {
                    return value
                } else if let value = value as? Float {
                    return value
                } else if let value = value as? Rotation {
                    return value.value
                } else if let value = value as? String {
                    return Int(decoding: value) ?? Float(value)
                } else {
                    return nil
                }
            case .float:
                return Float(byCasting: value)
            case .integer:
                return Int(byCasting: value)
            case .rotation:
                return Rotation(byCasting: value)
            case .pos:
                return Pos(byCasting: value)
            case .boolean:
                return Bool(byCasting: value)
            case .string:
                return String(byCasting: value)
            case .color:
                if let str = value as? String,
                   let i = Int(decoding: str) {
                    return ColorPaint(integer: i, alpha: false)
                }
                return nil
            default:
                return nil
            }
        } else if let to = to as? ArrayType,
                  let array = value as? GRPHArray,
                  array.wrapped.allSatisfy({ GRPHTypes.realType(of: $0, expected: to.content).isInstance(of: to.content) }) {
            return GRPHArray(array.wrapped, of: to.content)
        } else if let to = to as? MultiOrType {
            return cast(value: value, to: to.type1) ?? cast(value: value, to: to.type2)
        }
        return nil
    }
}

enum CastType {
    case typeCheck
    case conversion(optional: Bool)
    case strict(optional: Bool)
    
    var string: String {
        switch self {
        case .typeCheck:
            return "is"
        case .conversion(optional: let optional):
            return "as\(optional ? "?" : "")"
        case .strict(optional: let optional):
            return "as\(optional ? "?" : "")!"
        }
    }
    
    init?(_ str: String) {
        if str == "is" {
            self = .typeCheck
        } else if str.hasPrefix("as") {
            let optional = str.dropFirst(2).hasPrefix("?")
            if str.hasSuffix("!") {
                self = .strict(optional: optional)
            } else {
                self = .conversion(optional: optional)
            }
        } else {
            return nil
        }
    }
    
    var optional: Bool {
        switch self {
        case .typeCheck:
            return false
        case .conversion(optional: let optional):
            return optional
        case .strict(optional: let optional):
            return optional
        }
    }
}
