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
        let evaluated = try GRPHTypes.unbox(value: exp.eval(context: context))
        switch op {
        case .bitwiseComplement:
            return ~(evaluated as! Int)
        case .opposite:
            if let value = evaluated as? Int {
                return -value
            }
            return -(evaluated as! Float)
        case .not:
            return !(evaluated as! Bool)
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
