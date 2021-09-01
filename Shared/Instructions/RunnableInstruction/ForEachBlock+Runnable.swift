//
//  ForEachBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

extension ForEachBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool { true } // not called
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        var i = 0
        let arr = try array.eval(context: context) as! GRPHArray
        if mustRun(context: ctx) {
            throw GRPHRuntimeError(type: .unexpected, message: "Cannot fallthrough a #foreach block")
        }
        while !ctx.broken && i < arr.count {
            ctx.variables.removeAll()
            let v = Variable(name: varName, type: arr.content, content: arr.wrapped[i], final: !inOut)
            ctx.variables.append(v)
            if context.runtime.debugging {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
            try runChildren(context: ctx)
            if inOut {
                arr.wrapped[i] = ctx.variables.first(where: { $0.name == varName })!.content!
            }
            i += 1
        }
    }
}
