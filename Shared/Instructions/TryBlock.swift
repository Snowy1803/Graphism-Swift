//
//  TryBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct TryBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    var catches: [GRPHRuntimeError.RuntimeExceptionType?: CatchBlock] = [:]
    
    init(context: inout CompilingContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    func canRun(context: BlockRuntimeContext) throws -> Bool { true }
    
    func run(context: inout RuntimeContext) throws {
        do {
            let ctx = createContext(&context)
            try runChildren(context: ctx)
        } catch let e as GRPHRuntimeError {
            if let c = catches[e.type] {
                try c.exceptionCatched(context: &context, exception: e)
            } else if let c = catches[nil] {
                try c.exceptionCatched(context: &context, exception: e)
            } else {
                throw e
            }
        }
    }
    
    var name: String { "try" }
}
