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
    
    init(lineNumber: Int, context: inout GRPHContext, varName: String, array: Expression) throws {
        self.inOut = varName.hasPrefix("&") // new in Swift Edition
        self.varName = inOut ? String(varName.dropFirst()) : varName
        self.array = array
        self.lineNumber = lineNumber
        let ctx = createContext(&context)
        
        let type = try array.getType(context: context, infer: ArrayType(content: SimpleType.mixed))
        
        guard let arrtype = type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "#foreach needs an array, a \(type) was given")
        }
        
        guard GRPHCompiler.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        ctx.variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    func canRun(context: GRPHBlockContext) throws -> Bool { true } // not called
    
    func run(context: inout GRPHContext) throws {
        let ctx = createContext(&context)
        var i = 0
        let arr = try GRPHTypes.autobox(value: array.eval(context: context), expected: ArrayType(content: SimpleType.mixed)) as! GRPHArray
        if mustRun(context: ctx) {
            throw GRPHRuntimeError(type: .unexpected, message: "Cannot fallthrough a #foreach block")
        }
        while !ctx.broken && i < arr.count {
            ctx.variables.removeAll()
            let v = Variable(name: varName, type: arr.content, content: arr.wrapped[i], final: !inOut)
            ctx.variables.append(v)
            if context.runtime?.debugging ?? false {
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
