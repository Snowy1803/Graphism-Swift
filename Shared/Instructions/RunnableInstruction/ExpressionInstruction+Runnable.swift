//
//  ExpressionInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

extension ExpressionInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        _ = try expression.evalIfRunnable(context: context)
    }
}
