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
    var operands: SimpleType
    var unbox: Bool
    
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
                self.operands = .string
            } else {
                fallthrough
            }
        case .multiply, .divide, .modulo, .minus:
            guard try SimpleType.num.isInstance(context: context, expression: left),
                  try SimpleType.num.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two numbers")
            }
            if try SimpleType.integer.isInstance(context: context, expression: left),
               try SimpleType.integer.isInstance(context: context, expression: right) {
                operands = .integer
            } else {
                operands = .float
            }
        case .logicalAnd, .logicalOr:
            guard try SimpleType.boolean.isInstance(context: context, expression: left),
                  try SimpleType.boolean.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two booleans")
            }
            operands = .boolean
        case .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo:
            if try SimpleType.num.isInstance(context: context, expression: left),
               try SimpleType.num.isInstance(context: context, expression: right) {
                if try SimpleType.integer.isInstance(context: context, expression: left),
                   try SimpleType.integer.isInstance(context: context, expression: right) {
                    operands = .integer
                } else {
                    operands = .float
                }
            } else if try SimpleType.pos.isInstance(context: context, expression: left),
                      try SimpleType.pos.isInstance(context: context, expression: right) {
                operands = .pos
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two 'num' or two 'pos'")
            }
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            if try SimpleType.integer.isInstance(context: context, expression: left),
               try SimpleType.integer.isInstance(context: context, expression: right) {
                operands = .integer
            } else if try SimpleType.boolean.isInstance(context: context, expression: left),
                      try SimpleType.boolean.isInstance(context: context, expression: right) {
                operands = .boolean
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers or two booleans")
            }
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            guard try SimpleType.integer.isInstance(context: context, expression: left),
                  try SimpleType.integer.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers")
            }
            operands = .integer
        case .equal, .notEqual:
            operands = .mixed
            self.unbox = false
            return
        }
        self.unbox = try left.getType(context: context, infer: operands) is OptionalType ? true : right.getType(context: context, infer: operands) is OptionalType
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        let left = unbox ? try GRPHTypes.autobox(value: try self.left.eval(context: context), expected: operands) : try self.left.eval(context: context)
        switch op {
        case .logicalAnd:
            return left as! Bool
                ? (unbox ? try GRPHTypes.autobox(value: try self.right.eval(context: context), expected: operands) : try self.right.eval(context: context)) as! Bool
                : false
        case .logicalOr:
            return left as! Bool
                ? true
                : (unbox ? try GRPHTypes.autobox(value: try self.right.eval(context: context), expected: operands) : try self.right.eval(context: context)) as! Bool
        default:
            break
        }
        let right = unbox ? try GRPHTypes.autobox(value: try self.right.eval(context: context), expected: operands) : try self.right.eval(context: context)
        switch op {
        case .greaterOrEqualTo, .lessOrEqualTo, .greaterThan, .lessThan, .plus, .minus, .multiply, .divide, .modulo:
            // num: int or float
            let aleft = left as! GRPHNumber
            let aright = right as! GRPHNumber
            if operands == .integer {
                return run(aleft as! Int, aright as! Int)
            } else {
                return run(Float(grph: aleft), Float(grph: aright))
            }
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            // bool or int
            if let aleft = left as? Bool {
                switch op {
                case .bitwiseAnd:
                    return aleft && right as! Bool
                case .bitwiseOr:
                    return aleft || right as! Bool
                case .bitwiseXor:
                    return aleft != (right as! Bool)
                default:
                    fatalError()
                }
            }
            //  numbers
            fallthrough
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            return run(left as! Int, right as! Int)
        case .equal, .notEqual:
            return left.isEqual(to: right) == (op == .equal)
        case .concat:
            let aleft = left as! String
            let aright = right as! String
            return aleft + aright
        case .logicalAnd, .logicalOr:
            fatalError()
        }
    }
    
    func run(_ first: Float, _ second: Float) -> GRPHValue {
        switch op {
        case .greaterOrEqualTo:
            return first >= second
        case .lessOrEqualTo:
            return first <= second
        case .greaterThan:
            return first > second
        case .lessThan:
            return first < second
        case .plus:
            return first + second
        case .minus:
            return first - second
        case .multiply:
            return first * second
        case .divide:
            return first / second
        case .modulo:
            return fmodf(first, second)
        default:
            fatalError("Operator \(op.rawValue) doesn't take floats")
        }
    }
    
    func run(_ first: Int, _ second: Int) -> GRPHValue {
        switch op {
        case .bitwiseAnd:
            return first & second
        case .bitwiseOr:
            return first | second
        case .bitwiseXor:
            return first ^ second
        case .bitshiftLeft:
            return first << second
        case .bitshiftRight:
            return first >> second
        case .bitrotation:
            return Int(bitPattern: UInt(bitPattern: first) >> UInt(second))
        case .greaterOrEqualTo:
            return first >= second
        case .lessOrEqualTo:
            return first <= second
        case .greaterThan:
            return first > second
        case .lessThan:
            return first < second
        case .plus:
            return first + second
        case .minus:
            return first - second
        case .multiply:
            return first * second
        case .divide:
            return first / second
        case .modulo:
            return first % second
        default:
            fatalError("Operator \(op.rawValue) doesn't take integers")
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        switch op {
        case .logicalAnd, .logicalOr, .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo, .equal, .notEqual:
            return SimpleType.boolean
        case .bitshiftLeft, .bitshiftRight, .bitrotation, .bitwiseAnd, .bitwiseOr, .bitwiseXor, .plus, .minus, .multiply, .divide, .modulo, .concat:
            return operands
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
