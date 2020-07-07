//
//  GRPHRuntime.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

class GRPHRuntime: GRPHParser {
    
    // Debugging
    var debugging: Bool = false {
        didSet {
            if debugging && context != nil {
                for v in context.allVariables {
                    printout("[DEBUG VAR \(v.name)=\(v.content ?? "<@#invalid#@>")]")
                }
            }
        }
    }
    var debugStep: TimeInterval = 0
    var debugSemaphore = DispatchSemaphore(value: 0)
    
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
                    printout("[DEBUG LOC \(line.line)]")
                }
                if debugStep > 0 {
                    _ = debugSemaphore.wait(timeout: .now() + debugStep)
                }
                try line.safeRun(context: context)
                last = line
                i += 1
            }
            return true
        } catch let e as GRPHRuntimeError {
            printerr("GRPH Exited because a runtime exception was not catched")
            printerr("\(e.type.rawValue)Exception: \(e.message)")
            e.stack.forEach { print($0) }
        } catch let e {
            printerr("GRPH Exited after an unknown native error occurred")
            printerr("\(e)")
        }
        return false
    }
}

func printout(_ str: String, terminator: String = "\n") {
    guard let data = (str + terminator).data(using: .utf8) else { return }
    FileHandle.standardOutput.write(data)
}

func printerr(_ str: String, terminator: String = "\n") {
    guard let data = (str + terminator).data(using: .utf8) else { return }
    FileHandle.standardError.write(data)
}
