//
//  WhileBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class WhileBlock: BlockInstruction {
    var condition: Expression
    
    init(lineNumber: Int, context: GRPHContext, condition: Expression) throws {
        self.condition = condition
        super.init(lineNumber: lineNumber)
        if try !SimpleType.boolean.isInstance(context: context, expression: condition) {
            throw GRPHCompileError(type: .typeMismatch, message: "#while needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    override func canRun(context: GRPHContext) throws -> Bool {
        try GRPHTypes.autobox(value: condition.eval(context: context), expected: SimpleType.boolean) as! Bool
    }
    
    override func run(context: GRPHContext) throws {
        canNextRun = true
        broken = false
        while try mustRun(context: context) || (!broken && canRun(context: context)) {
            variables.removeAll()
            try runChildren(context: context)
        }
    }
    
    override var name: String { "while \(condition.string)" }
}
