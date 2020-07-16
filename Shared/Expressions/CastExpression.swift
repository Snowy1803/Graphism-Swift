//
//  CastExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct CastExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.+) (as|is) (\(Expressions.typePattern))$")
    
    var from: Expression
    var cast: Bool
    var to: GRPHType
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        if cast {
            let value = try GRPHTypes.autobox(value: try from.eval(context: context), expected: to)
            // boxing, unboxing and all null values returns here
            if GRPHTypes.type(of: value).isInstance(of: to) {
                return value
            }
            if let result = CastExpression.cast(value: value, to: to) {
                return result
            }
            throw GRPHRuntimeError(type: .cast, message: "Couldn't cast from \(GRPHTypes.type(of: value)) to \(to)")
        } else {
            return GRPHTypes.type(of: try from.eval(context: context)).isInstance(of: to) // no autoboxing in is
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        cast ? to : SimpleType.boolean
    }
    
    var string: String { "\(from.string) \(cast ? "as" : "is") \(to.string)" }
    
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
        }
        return nil
    }
}
