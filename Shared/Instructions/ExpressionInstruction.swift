//
//  ExpressionInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct ExpressionInstruction: Instruction {
    let lineNumber: Int
    let expression: Expression
    
    func run(context: GRPHContext) throws {
        _ = try expression.eval(context: context)
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)\(expression)\n"
    }
}
