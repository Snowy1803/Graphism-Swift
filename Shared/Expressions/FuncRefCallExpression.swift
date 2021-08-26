//
//  FuncRefCallExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

struct FuncRefCallExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^([A-Za-z0-9_$]+)\\^\\[(.*)\\]$")
    
    let varName: String
    let values: [Expression?]
    
    init(ctx: GRPHContext, varName: String, values: [Expression], asInstruction: Bool = false) throws {
        self.varName = varName
        
        guard let variable = ctx.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'")
        }
        
        let autoboxedType = GRPHTypes.autoboxed(type: variable.type, expected: SimpleType.funcref)
        
        guard let function = autoboxedType as? FuncRefType else {
            if autoboxedType as? SimpleType == SimpleType.funcref {
                throw GRPHCompileError(type: .typeMismatch, message: "Funcref call on non-specialized funcref variable, add return type and parameter types to the variable type, or use reflection")
            }
            throw GRPHCompileError(type: .typeMismatch, message: "Funcref call on variable of type '\(variable.type)' (expected funcref)")
        }
        
        var ourvalues: [Expression?] = []
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        var nextParam = 0
        for param in values {
            guard let par = try function.parameter(index: nextParam, context: ctx, exp: param) else {
                if nextParam >= function.parameters.count && !function.varargs {
                    throw GRPHCompileError(type: .typeMismatch, message: "Unexpected argument '\(param.string)' for out of bounds parameter in funcref call '\(varName)'")
                }
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: function.parameter(index: nextParam).type))' in funcref call '\(varName)'")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(try GRPHTypes.autobox(context: ctx, expression: param, expected: par.param.type))
            // at pars[nextParam - 1] aka current param
        }
        while nextParam < function.parameters.count {
            guard function.parameters[nextParam].optional else {
                throw GRPHCompileError(type: .invalidArguments, message: "No argument passed to parameter '\(function.parameters[nextParam].name)' in funcref call '\(varName)'")
            }
            nextParam += 1
        }
        self.values = ourvalues
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        guard let variable = context.findVariable(named: varName) else {
            throw GRPHRuntimeError(type: .invalidArgument, message: "Unknown variable '\(varName)'")
        }
        
        guard let funcref = variable.content as? FuncRef else {
            throw GRPHRuntimeError(type: .typeMismatch, message: "Funcref call on non-funcref value")
        }
        
        do {
            return try funcref.execute(context: context, params: try values.map { try $0?.eval(context: context) })
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(funcref.funcName) in funcref \(varName)")
            throw e
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        guard let variable = context.findVariable(named: varName),
              let funcref = variable.type as? FuncRefType else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown funcref '\(varName)'")
        }
        return funcref.returnType
    }
    
    var string: String {
        "\(varName)^[\(FuncRefType(returnType: SimpleType.void, parameterTypes: []).formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    var needsBrackets: Bool { false }
}
