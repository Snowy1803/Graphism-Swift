//
//  IfBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct IfBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    let condition: Expression
    
    init(lineNumber: Int, context: inout GRPHContext, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: context, expression: condition, expected: SimpleType.boolean)
        createContext(&context)
        guard try self.condition.getType(context: context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#if needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    func canRun(context: GRPHBlockContext) throws -> Bool {
        try condition.eval(context: context) as! Bool
    }
    
    var name: String { "if \(condition.string)" }
}

struct ElseIfBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    let condition: Expression
    
    init(lineNumber: Int, context: inout GRPHContext, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: context, expression: condition, expected: SimpleType.boolean)
        createContext(&context)
        guard try self.condition.getType(context: context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#elseif needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    func canRun(context: GRPHBlockContext) throws -> Bool {
        if let last = context.parent.last as? GRPHBlockContext {
            context.canNextRun = last.canNextRun
            return try context.canNextRun && condition.eval(context: context) as! Bool
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "#elseif must follow another block instruction")
        }
    }
    
    var name: String { "elseif \(condition.string)" }
}

struct ElseBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    init(context: inout GRPHContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    func canRun(context: GRPHBlockContext) throws -> Bool {
        if let last = context.parent.last as? GRPHBlockContext {
            return last.canNextRun
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "#else must follow another block instruction")
        }
    }
    
    var name: String { "else" }
}
