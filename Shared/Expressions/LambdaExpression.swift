//
//  LambdaExpression.swift
//  LambdaExpression
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

struct LambdaExpression: Expression {
    let lambda: Lambda
    let capturedVarNames: [String]
    
    init(context: CompilingContext, literal: String, infer: GRPHType?) throws {
        guard let type = infer as? FuncRefType else {
            // TODO could determine the type from the expression
            throw GRPHCompileError(type: .typeMismatch, message: "Could not determine the type of the lambda, try inserting 'as funcref<returnType><>'")
        }
        
        // new capturing context
        let compiler = context.compiler
        let lambdaContext = LambdaCompilingContext(compiler: compiler, parent: context)
        
        for param in type.parameters {
            lambdaContext.addVariable(Variable(name: param.name, type: param.type, final: true, compileTime: true), global: false)
        }
        
        // if void
        if type.returnType.isTheVoid {
            let prevContext = compiler.context
            compiler.context = lambdaContext
            
            let instruction: Instruction
            if literal.isEmpty {
                instruction = ExpressionInstruction(lineNumber: compiler.lineNumber, expression: try Expressions.parse(context: context, infer: SimpleType.void, literal: "void.VOID"))
            } else if let resolved = try (compiler as! GRPHCompiler).resolveInstruction(literal: literal)?.instruction {
                instruction = resolved
            } else {
                throw GRPHCompileError(type: .parse, message: "Invalid instruction in void lambda")
            }
            try lambdaContext.accepts(instruction: instruction)
            lambda = Lambda(currentType: type, instruction: instruction)
            
            compiler.context = prevContext
        } else {
            let expr = try Expressions.parse(context: lambdaContext, infer: type.returnType, literal: literal)
            let exprType = try expr.getType(context: lambdaContext, infer: type.returnType)
            guard exprType.isInstance(of: type.returnType) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Lambda of type '\(type)' must return value of type '\(type.returnType)', found value of type '\(exprType.string)'")
            }
            lambda = Lambda(currentType: type, instruction: ExpressionInstruction(lineNumber: compiler.lineNumber, expression: expr))
        }
        capturedVarNames = Array(lambdaContext.capturedVarNames)
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        lambda.currentType
    }
    
    var string: String {
        let instr = lambda.instruction.toString(indent: "").dropLast()
        let colon = instr.firstIndex(of: ":")!
        return "^[\(instr[instr.index(after: colon)...])]"
    }
    
    var needsBrackets: Bool { false }
}
