//
//  TryBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class TryBlock: BlockInstruction {
    var catches: [GRPHRuntimeError.RuntimeExceptionType?: CatchBlock] = [:]
    
    override func run(context: inout GRPHContext) throws {
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
    
    override var name: String { "try" }
}
