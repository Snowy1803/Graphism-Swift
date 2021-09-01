//
//  VariableExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct VariableExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^[A-Za-z0-9_$]+$")
    
    let name: String
    
    func eval(context: RuntimeContext) throws -> GRPHValue {
        if let v = context.findVariable(named: name) {
            return v.content!
        }
        throw GRPHRuntimeError(type: .invalidArgument, message: "Undeclared variable '\(name)'")
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if let v = context.findVariable(named: name) {
            return v.type
        }
        throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(name)'")
    }
    
    var string: String { name }
    
    var needsBrackets: Bool { false }
}

extension VariableExpression: AssignableExpression {
    func checkCanAssign(context: CompilingContext) throws {
        guard let v = context.findVariable(named: name),
              !v.final else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot assign to final variable '\(name)'")
        }
    }
    
    func eval(context: RuntimeContext, cache: inout [GRPHValue]) throws -> GRPHValue {
        try eval(context: context)
    }
    
    func assign(context: RuntimeContext, value: GRPHValue, cache: inout [GRPHValue]) throws {
        if let v = context.findVariable(named: name) {
            if v.name == "back" {
                let new = value as! GImage
                let old = context.runtime.image
                old.paint = new.paint
                old.size = new.size
                old.shapes = new.shapes
            } else {
                try v.setContent(value)
            }
            if v.type.isInstance(of: SimpleType.shape) {
                context.runtime.triggerAutorepaint()
            }
            if context.runtime.debugging {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
        }
    }
}
