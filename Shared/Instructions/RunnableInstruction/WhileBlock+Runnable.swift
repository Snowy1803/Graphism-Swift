//
//  WhileBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

extension WhileBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        try condition.eval(context: context) as! Bool
    }
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        while try mustRun(context: ctx) || (!ctx.broken && canRun(context: ctx)) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
}
