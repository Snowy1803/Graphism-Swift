//
//  ThrowInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

extension ThrowInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        throw GRPHRuntimeError(type: type, message: try message.evalIfRunnable(context: context) as! String)
    }
}
