//
//  IfBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

class IfBlock: BlockInstruction {
    let condition: Expression
    
    init(lineNumber: Int, context: inout GRPHContext, condition: Expression) throws {
        self.condition = condition
        super.init(context: &context, lineNumber: lineNumber)
        if try !SimpleType.boolean.isInstance(context: context, expression: condition) {
            throw GRPHCompileError(type: .typeMismatch, message: "#if needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    override func canRun(context: GRPHBlockContext) throws -> Bool {
        try GRPHTypes.autobox(value: condition.eval(context: context), expected: SimpleType.boolean) as! Bool
    }
    
    override var name: String { "if \(condition.string)" }
}

class ElseIfBlock: BlockInstruction {
    let condition: Expression
    
    init(lineNumber: Int, context: inout GRPHContext, condition: Expression) throws {
        self.condition = condition
        super.init(context: &context, lineNumber: lineNumber)
        if try !SimpleType.boolean.isInstance(context: context, expression: condition) {
            throw GRPHCompileError(type: .typeMismatch, message: "#elseif needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    override func canRun(context: GRPHBlockContext) throws -> Bool {
        if let last = context.parent.last as? GRPHBlockContext {
            context.canNextRun = last.canNextRun
            return try context.canNextRun && GRPHTypes.autobox(value: condition.eval(context: context), expected: SimpleType.boolean) as! Bool
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "#elseif must follow another block instruction")
        }
    }
    
    override var name: String { "elseif \(condition.string)" }
}

class ElseBlock: BlockInstruction {
    override init(context: inout GRPHContext, lineNumber: Int) {
        super.init(context: &context, lineNumber: lineNumber)
    }
    
    override func canRun(context: GRPHBlockContext) throws -> Bool {
        if let last = context.parent.last as? GRPHBlockContext {
            return last.canNextRun
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "#else must follow another block instruction")
        }
    }
    
    override var name: String { "else" }
}
