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

struct Expressions {
    static let typePattern = try! NSRegularExpression(pattern: "[A-Za-z|<>{}?]+")
    
    private init() {}
    
    static func parse(context: GRPHContext, infer: GRPHType, literal str: String) throws -> Expression {
        if str.hasPrefix("[") && str.hasSuffix("]") {
            return try parse(context: context, infer: infer, literal: "\(str.dropFirst().dropLast())")
        }
        
        if let direction = Direction(rawValue: str) {
            return ConstantExpression(direction: direction)
        } else if let stroke = Stroke(rawValue: str) {
            return ConstantExpression(stroke: stroke)
        } else if str == "true" || str == "false" {
            return ConstantExpression(boolean: str == "true")
        }
        // null
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
        // cast
        if let result = ConstantExpression.posPattern.firstMatch(string: str) {
            if let x = Float(result[1]!),
               let y = Float(result[2]!) {
                return ConstantExpression(pos: Pos(x: x, y: y))
            } else {
                throw GRPHCompileError(type: .parse, message: "Could not parse position '\(str)'")
            }
        }
        // function call
        // comparison (* 4 priorities)
        // constructor
        // math (* 2 priorities)
        // unaries
        // fields
        throw GRPHCompileError(type: .parse, message: "Could not parse expression '\(str)'")
    }
}
