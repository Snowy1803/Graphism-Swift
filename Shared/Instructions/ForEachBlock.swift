//
//  ForEachBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct ForEachBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    let varName: String
    let array: Expression
    let inOut: Bool
    
    init(lineNumber: Int, context: inout CompilingContext, varName: String, array: Expression) throws {
        self.inOut = varName.hasPrefix("&") // new in Swift Edition
        self.varName = inOut ? String(varName.dropFirst()) : varName
        self.array = try GRPHTypes.autobox(context: context, expression: array, expected: SimpleType.mixed.inArray)
        self.lineNumber = lineNumber
        let ctx = createContext(&context)
        
        let type = try array.getType(context: context, infer: SimpleType.mixed.inArray)
        
        guard let arrtype = type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "#foreach needs an array, a \(type) was given")
        }
        
        guard GRPHCompiler.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        ctx.variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    func canRun(context: BlockRuntimeContext) throws -> Bool { true } // not called
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        var i = 0
        let arr = try array.eval(context: context) as! GRPHArray
        if mustRun(context: ctx) {
            throw GRPHRuntimeError(type: .unexpected, message: "Cannot fallthrough a #foreach block")
        }
        while !ctx.broken && i < arr.count {
            ctx.variables.removeAll()
            let v = Variable(name: varName, type: arr.content, content: arr.wrapped[i], final: !inOut)
            ctx.variables.append(v)
            if context.runtime.debugging {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
            try runChildren(context: ctx)
            if inOut {
                arr.wrapped[i] = ctx.variables.first(where: { $0.name == varName })!.content!
            }
            i += 1
        }
    }
    
    var name: String { "foreach \(inOut ? "&" : "")\(varName) : \(array.string)" }
}
