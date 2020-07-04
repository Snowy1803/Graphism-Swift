//
//  TryBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class TryBlock: BlockInstruction {
    var catches: [GRPHRuntimeError.RuntimeExceptionType?: CatchBlock] = [:]
    
    override init(lineNumber: Int) {
        super.init(lineNumber: lineNumber)
    }
    
    override func run(context: GRPHContext) throws {
        do {
            variables.removeAll()
            try runChildren(context: context)
        } catch let e as GRPHRuntimeError {
            if let c = catches[e.type] {
                try c.exceptionCatched(context: context, exception: e)
            } else if let c = catches[nil] {
                try c.exceptionCatched(context: context, exception: e)
            } else {
                throw e
            }
        }
    }
    
    override var name: String { "try" }
}
