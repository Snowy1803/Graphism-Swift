//
//  UnaryExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct UnaryExpression: Expression {
    
    var exp: Expression
    var op: UnaryOperator
    
    init(context: GRPHContext, op: String, exp: Expression) throws {
        self.op = UnaryOperator(rawValue: op)!
        self.exp = exp
        switch self.op {
        case .bitwiseComplement:
            guard try SimpleType.integer.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs an integer")
            }
        case .opposite:
            guard try SimpleType.num.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs a number")
            }
        case .not:
            guard try SimpleType.boolean.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs a boolean")
            }
        }
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        switch op {
        case .bitwiseComplement:
            return ~(try GRPHTypes.autobox(value: exp.eval(context: context), expected: SimpleType.integer) as! Int)
        case .opposite:
            let value = try GRPHTypes.autobox(value: exp.eval(context: context), expected: SimpleType.num)
            if let value = value as? Int {
                return -value
            }
            return -(value as! Float)
        case .not:
            return !(try GRPHTypes.autobox(value: exp.eval(context: context), expected: SimpleType.boolean) as! Bool)
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        switch op {
        case .bitwiseComplement:
            return SimpleType.integer
        case .opposite:
            return try exp.getType(context: context, infer: infer)
        case .not:
            return SimpleType.boolean
        }
    }
    
    var needsBrackets: Bool { false }
    
    var string: String { "\(op.rawValue)\(exp.bracketized)" }
}


enum UnaryOperator: String {
    case bitwiseComplement = "~"
    case opposite = "-"
    case not = "!"
}
