//
//  WhileBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class WhileBlock: BlockInstruction {
    let condition: Expression
    
    init(lineNumber: Int, context: inout GRPHContext, condition: Expression) throws {
        self.condition = condition
        super.init(context: &context, lineNumber: lineNumber)
        if try !SimpleType.boolean.isInstance(context: context, expression: condition) {
            throw GRPHCompileError(type: .typeMismatch, message: "#while needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    override func canRun(context: GRPHContext) throws -> Bool {
        try GRPHTypes.autobox(value: condition.eval(context: context), expected: SimpleType.boolean) as! Bool
    }
    
    override func run(context: inout GRPHContext) throws {
        let ctx = createContext(&context)
        while try mustRun(context: ctx) || (!ctx.broken && canRun(context: ctx)) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
    
    override var name: String { "while \(condition.string)" }
}
