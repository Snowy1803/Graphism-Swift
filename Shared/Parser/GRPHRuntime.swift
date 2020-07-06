//
//  GRPHRuntime.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

class GRPHRuntime: GRPHParser {
    
    // Debugging
    var debugging: Bool = false
    var debugStep: TimeInterval = 0
    
    var globalVariables: [Variable]
    var instructions: [Instruction]
    var timestamp: Date!
    var context: GRPHContext!
    
    init(instructions: [Instruction], globalVariables: [Variable] = []) {
        self.instructions = instructions
        self.globalVariables = globalVariables
    }
    
    convenience init(compiler: GRPHCompiler) {
        self.init(instructions: compiler.instructions, globalVariables: compiler.globalVariables.filter { !$0.compileTime })
    }
    
    func run() -> Bool {
        timestamp = Date()
        context = GRPHContext(parser: self)
        do {
            var last: Instruction?
            var i = 0
            while i < instructions.count && !Thread.current.isCancelled {
                let line = instructions[i]
                context.last = last
                if debugging {
                    print("[DEBUG LOC \(line.line)]")
                }
                Thread.sleep(forTimeInterval: context.runtime?.debugStep ?? 0) // should be cancellable? idk
                try line.safeRun(context: context)
                last = line
                i += 1
            }
            return true
        } catch let e as GRPHRuntimeError {
            print("GRPH Exited because a runtime exception was not catched")
            print("\(e.type.rawValue)Exception: \(e.message)")
            e.stack.forEach { print($0) }
        } catch let e {
            print("GRPH Exited after an unknown native error occurred")
            print(e)
        }
        return false
    }
}
