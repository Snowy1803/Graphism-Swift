//
//  RequiresInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 15/07/2020.
//

import Foundation

extension RequiresInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        try run(context: context)
    }
}
