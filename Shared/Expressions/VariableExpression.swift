//
//  VariableExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct VariableExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^[A-Za-z0-9_$]+$")
    
    var name: String
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        if let v = context.findVariable(named: name) {
            return v.content!
        }
        throw GRPHRuntimeError(type: .invalidArgument, message: "Undeclared variable '\(name)'")
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        if let v = context.findVariable(named: name) {
            return v.type
        }
        throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(name)'")
    }
    
    var string: String { name }
    
    var needsBrackets: Bool { false }
}
