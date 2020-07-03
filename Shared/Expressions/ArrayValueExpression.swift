//
//  ArrayValueExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct ArrayValueExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^([$A-Za-z_][A-Za-z0-9_]*)\\{(.*)\\}$")
    
    var varName: String
    var index: Expression
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        guard let val = context.findVariable(named: varName)?.content as? GRPHArray else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array") // runtime
        }
        guard let i = try GRPHTypes.autobox(value: try index.eval(context: context), expected: SimpleType.integer) as? Int else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression index couldn't be resolved as an integer") // runtime
        }
        guard i < val.count else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array out of bounds; index \(i) not found in array of length \(val.count))") // runtime
        }
        return val.wrapped[i]
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        guard let v = context.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'")
        }
        guard let type = v.type as? ArrayType else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array variable")
        }
        return type.content
    }
    
    var string: String { "\(varName){\(index.string)}" }
    
    var needsBrackets: Bool { false }
}
