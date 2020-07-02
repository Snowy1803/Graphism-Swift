//
//  BinaryExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct BinaryExpression: Expression {
    static let signs1 = try! NSRegularExpression(pattern: "&&|\\|\\|")
    static let signs2 = try! NSRegularExpression(pattern: ">=|<=|>|<")
    static let signs3 = try! NSRegularExpression(pattern: "&|\\||\\^|<<|>>|>>>")
    static let signs4 = try! NSRegularExpression(pattern: "==|!=")
    static let signs5 = try! NSRegularExpression(pattern: "\\+|\\-")
    static let signs6 = try! NSRegularExpression(pattern: "\\*|\\/|\\%")
    
    var left, right: Expression
    var op: BinaryOperator
    
    init(context: GRPHContext, left: Expression, op: String, right: Expression) throws {
        self.left = left
        self.right = right
        self.op = BinaryOperator(rawValue: op)!
        // TYPE CHECKS
        switch self.op {
        case .plus, .concat: // concat impossible here
            if try SimpleType.string.isInstance(context: context, expression: left),
               try SimpleType.string.isInstance(context: context, expression: right) {
                self.op = .concat
            } else {
                fallthrough
            }
        case .multiply, .divide, .modulo, .minus:
            guard try SimpleType.num.isInstance(context: context, expression: left),
                  try SimpleType.num.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two numbers")
            }
        case .logicalAnd, .logicalOr:
            guard try SimpleType.boolean.isInstance(context: context, expression: left),
                  try SimpleType.boolean.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two booleans")
            }
        case .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo:
            guard try (SimpleType.num.isInstance(context: context, expression: left) &&
                SimpleType.num.isInstance(context: context, expression: right)) ||
                  (SimpleType.pos.isInstance(context: context, expression: left) &&
                   SimpleType.pos.isInstance(context: context, expression: right)) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two 'num' or two 'pos'")
            }
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            guard try (SimpleType.integer.isInstance(context: context, expression: left) &&
                SimpleType.integer.isInstance(context: context, expression: right)) ||
                  (SimpleType.boolean.isInstance(context: context, expression: left) &&
                   SimpleType.boolean.isInstance(context: context, expression: right)) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers or two booleans")
            }
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            guard try SimpleType.integer.isInstance(context: context, expression: left),
                  try SimpleType.integer.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers")
            }
        case .equal, .notEqual:
            break // No type checks
        }
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        fatalError("TODO")
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        switch op {
        case .logicalAnd, .logicalOr, .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo, .equal, .notEqual:
            return SimpleType.boolean
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            return SimpleType.integer
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            return try SimpleType.integer.isInstance(context: context, expression: left) ? SimpleType.integer : SimpleType.boolean
        case .plus, .minus, .multiply, .divide, .modulo: // modulo is objc 'fmodf'
            return try SimpleType.integer.isInstance(context: context, expression: left)
                    && SimpleType.integer.isInstance(context: context, expression: right)
                     ? SimpleType.integer : SimpleType.float
        case .concat:
            return SimpleType.string
        }
    }
    
    var string: String {
        "\(left.bracketized) \(op.string) \(right.bracketized)"
    }
    
    var needsBrackets: Bool { true }
}

enum BinaryOperator: String {
    case logicalAnd = "&&"
    case logicalOr = "||"
    case greaterOrEqualTo = ">="
    case lessOrEqualTo = "<="
    case greaterThan = ">"
    case lessThan = "<"
    case bitwiseAnd = "&"
    case bitwiseOr = "|"
    case bitwiseXor = "^"
    case bitshiftLeft = "<<"
    case bitshiftRight = ">>"
    case bitrotation = ">>>"
    case equal = "=="
    case notEqual = "!="
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
    case concat = "<+>" // Sign not actually used
    
    var string: String {
        switch self {
        case .concat:
            return "+"
        default:
            return rawValue
        }
    }
}
