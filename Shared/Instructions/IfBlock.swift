//
//  IfBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

class IfBlock: BlockInstruction {
    var condition: Expression
    
    init(lineNumber: Int, context: GRPHContext, condition: Expression) throws {
        self.condition = condition
        super.init(lineNumber: lineNumber)
        if try !SimpleType.boolean.isInstance(context: context, expression: condition) {
            throw GRPHCompileError(type: .typeMismatch, message: "#if needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    override func canRun(context: GRPHContext) throws -> Bool {
        try GRPHTypes.autobox(value: condition.eval(context: context), expected: SimpleType.boolean) as! Bool
    }
    
    override var name: String { "if \(condition.string)" }
}
