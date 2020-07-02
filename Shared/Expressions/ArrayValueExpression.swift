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
        // TODO
        throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array") // runtime
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        guard let v = context.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'") // runtime
        }
        guard let type = v.type as? ArrayType else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array variable") // runtime
        }
        return type.content
    }
    
    var string: String { "\(varName){\(index.string)}" }
    
    var needsBrackets: Bool { false }
}
