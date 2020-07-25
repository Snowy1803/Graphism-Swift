//
//  CatchBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class CatchBlock: BlockInstruction {
    let varName: String
    var def: String = ""
    
    init(lineNumber: Int, context: inout GRPHContext, varName: String) throws {
        self.varName = varName
        super.init(context: &context, lineNumber: lineNumber)
        
        guard GRPHCompiler.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        
        (context as! GRPHBlockContext).variables.append(Variable(name: varName, type: SimpleType.string, final: true, compileTime: true))
    }
    
    func exceptionCatched(context: inout GRPHContext, exception: GRPHRuntimeError) throws {
        do {
            let ctx = createContext(&context)
            let v = Variable(name: varName, type: SimpleType.string, content: exception.message, final: true)
            ctx.variables.append(v)
            if context.runtime?.debugging ?? false {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
            try self.runChildren(context: ctx)
        } catch var exception as GRPHRuntimeError {
            exception.stack.append("\tat \(type(of: self)); line \(line)")
            throw exception
        }
    }
    
    func addError(type: String) {
        if def.isEmpty {
            def = type
        } else {
            def += " | \(type)"
        }
    }
    
    override func canRun(context: GRPHContext) throws -> Bool { false }
    
    override var name: String { "catch \(varName) : \(def)" }
}
