//
//  Expression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

protocol Expression {
    
    func eval(context: GRPHContext) throws -> GRPHValue
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType
    
    var string: String { get }
    
    var needsBrackets: Bool { get }
}

extension Expression {
    var bracketized: String {
        needsBrackets ? "[\(string)]" : string
    }
}

struct Expressions {
    static let typePattern = "[A-Za-z|<>{}?]+"
    
    private init() {}
    
    static func parse(context: GRPHContext, infer: GRPHType?, literal str: String) throws -> Expression {
        if str.hasPrefix("[") && str.hasSuffix("]") {
            return try parse(context: context, infer: infer, literal: "\(str.dropFirst().dropLast())")
        }
        
        if let direction = Direction(rawValue: str) {
            return ConstantExpression(direction: direction)
        } else if let stroke = Stroke(rawValue: str) {
            return ConstantExpression(stroke: stroke)
        } else if str == "true" || str == "false" {
            return ConstantExpression(boolean: str == "true")
        } else if str == "null" {
            return NullExpression()
        }
        if str.hasSuffix("°") || str.hasSuffix("º"), // degree sign, but also allow ordinal indicator, more accessible on Apple keyboards
           let result = ConstantExpression.intPattern.firstMatch(string: String(str.dropLast())),
           let int = Int(result[0]!) {
            return ConstantExpression(rot: Rotation(value: int))
        }
        if ConstantExpression.floatPattern.firstMatch(string: str) != nil,
           let float = Float(str.hasSuffix("f") || str.hasSuffix("F") ? "\(str.dropLast())" : str) {
            return ConstantExpression(float: float)
        }
        if ConstantExpression.intPattern.firstMatch(string: str) != nil,
           let int = Int(str) {
            return ConstantExpression(int: int)
        }
        if let result = ArrayValueExpression.pattern.firstMatch(string: str) {
            return ArrayValueExpression(varName: result[1]!, index: try parse(context: context, infer: SimpleType.integer, literal: result[2]!))
        }
        if VariableExpression.pattern.firstMatch(string: str) != nil {
            return VariableExpression(name: str)
        }
        // array declaration
        if let result = CastExpression.pattern.firstMatch(string: str) {
            if let type = GRPHTypes.parse(context: context, literal: result[3]!) {
                return CastExpression(from: try parse(context: context, infer: nil, literal: result[1]!), cast: result[2]! == "as", to: type)
            } else {
                throw GRPHCompileError(type: .parse, message: "Unknown type '\(result[3]!)' in cast")
            }
        }
        if let result = ConstantExpression.posPattern.firstMatch(string: str) {
            if let x = Float(result[1]!),
               let y = Float(result[2]!) {
                return ConstantExpression(pos: Pos(x: x, y: y))
            } else {
                throw GRPHCompileError(type: .parse, message: "Could not parse position '\(str)'")
            }
        }
        // function call
        if let exp = try findBinary(context: context, str: str, regex: BinaryExpression.signs1)
                      ?? findBinary(context: context, str: str, regex: BinaryExpression.signs2)
                      ?? findBinary(context: context, str: str, regex: BinaryExpression.signs3)
                      ?? findBinary(context: context, str: str, regex: BinaryExpression.signs4) {
            return exp
        }
        // constructor
        if let exp = try findBinary(context: context, str: str, regex: BinaryExpression.signs5)
                      ?? findBinary(context: context, str: str, regex: BinaryExpression.signs6) {
            return exp
        }
        if let chr = str.first,
           chr == "~" || chr == "-" || chr == "!" {
            return try UnaryExpression(context: context, op: String(chr), exp: parse(context: context, infer: infer, literal: String(str.dropFirst())))
        }
        // fields
        throw GRPHCompileError(type: .parse, message: "Could not parse expression '\(str)'")
    }
    
    private static func findBinary(context: GRPHContext, str: String, regex: NSRegularExpression) throws -> BinaryExpression? {
        var exp1 = "",
            exp2 = "",
            op = ""
        regex.allMatches(in: str) { range in
            let left = str[..<range.lowerBound]
            let right = str[range.upperBound...]
            if checkBalance(literal: left) && checkBalance(literal: right) {
                exp1 = left.trimmingCharacters(in: .whitespaces)
                exp2 = right.trimmingCharacters(in: .whitespaces)
                op = String(str[range])
            }
        }
        if !op.isEmpty {
            return try BinaryExpression(context: context, left: try parse(context: context, infer: nil, literal: exp1), op: op, right: try parse(context: context, infer: nil, literal: exp2))
        }
        return nil
    }
    
    private static func checkBalance<S: StringProtocol>(literal str: S) -> Bool {
        if str.isEmpty {
            return false // Fix error from Java; unary - matches empty substraction instead of unary
        }
        var brackets = 0, parenthesis = 0, curlies = 0
        for c in str {
            if c == "[" {
                brackets += 1
            } else if c == "(" {
                parenthesis += 1
            } else if c == "{" {
                curlies += 1
            } else if c == "]" {
                brackets -= 1
                if brackets < 0 {
                    return false
                }
            } else if c == ")" {
                parenthesis -= 1
                if parenthesis < 0 {
                    return false
                }
            } else if c == "}" {
                curlies -= 1
                if curlies < 0 {
                    return false
                }
            }
        }
        return brackets == 0 && parenthesis == 0 && curlies == 0
    }
}
