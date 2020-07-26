//
//  WhileBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct WhileBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    let condition: Expression
    
    init(lineNumber: Int, context: inout GRPHContext, condition: Expression) throws {
        self.condition = condition
        self.lineNumber = lineNumber
        createContext(&context)
        if try !SimpleType.boolean.isInstance(context: context, expression: condition) {
            throw GRPHCompileError(type: .typeMismatch, message: "#while needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    func canRun(context: GRPHBlockContext) throws -> Bool {
        try GRPHTypes.autobox(value: condition.eval(context: context), expected: SimpleType.boolean) as! Bool
    }
    
    func run(context: inout GRPHContext) throws {
        let ctx = createContext(&context)
        while try mustRun(context: ctx) || (!ctx.broken && canRun(context: ctx)) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
    
    var name: String { "while \(condition.string)" }
}
