//
//  CatchBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class CatchBlock: BlockInstruction {
    var varName: String
    var def: String = ""
    
    init(lineNumber: Int, context: GRPHContext, varName: String) throws {
        self.varName = varName
        super.init(lineNumber: lineNumber)
        
        guard ForBlock.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        
        variables.append(Variable(name: varName, type: SimpleType.string, final: true, compileTime: true))
    }
    
    func exceptionCatched(context: GRPHContext, exception: GRPHRuntimeError) throws {
        do {
            variables.removeAll()
            broken = false
            variables.append(Variable(name: varName, type: SimpleType.string, content: exception.message, final: true))
            try self.runChildren(context: context)
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
