//
//  Instruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

protocol Instruction {
    var lineNumber: Int { get }
    
    func run(context: inout RuntimeContext) throws
    
    /// Must end with a newline
    func toString(indent: String) -> String
}

extension Instruction {
    func safeRun(context: inout RuntimeContext) throws {
        do {
            try self.run(context: &context)
        } catch var exception as GRPHRuntimeError {
            exception.stack.append("\tat \(type(of: self)); line \(line)")
            throw exception
        }
    }
    
    var line: Int {
        lineNumber + 1
    }
}
