//
//  ArrayValueExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct ArrayValueExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^([$A-Za-z_][A-Za-z0-9_]*)\\{(.*)\\}$")
    
    let varName: String
    let index: Expression?
    let removing: Bool
    
    internal init(context: GRPHContext, varName: String, index: Expression?, removing: Bool) throws {
        self.varName = varName
        self.index = index == nil ? nil : try GRPHTypes.autobox(context: context, expression: index!, expected: SimpleType.integer)
        self.removing = removing
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        guard let val = context.findVariable(named: varName)?.content as? GRPHArray else {
            throw GRPHRuntimeError(type: .invalidArgument, message: "Array expression with non-array")
        }
        guard val.count > 0 else {
            throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds; array is empty")
        }
        if let index = index {
            guard let i = try index.eval(context: context) as? Int else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Array expression index couldn't be resolved as an integer")
            }
            guard i < val.count else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds; index \(i) not found in array of length \(val.count))")
            }
            if removing {
                return val.wrapped.remove(at: i)
            }
            return val.wrapped[i]
        } else if removing {
            return val.wrapped.removeLast()
        } else {
            return val.wrapped.last!
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        guard let v = context.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'")
        }
        guard let type = GRPHTypes.autoboxed(type: v.type, expected: ArrayType(content: SimpleType.mixed)) as? ArrayType else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array variable")
        }
        return type.content
    }
    
    var string: String { "\(varName){\(index?.string ?? "")\(removing ? "-" : "")}" }
    
    var needsBrackets: Bool { false }
}
