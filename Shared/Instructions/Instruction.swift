//
//  Instruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

protocol Instruction {
    var lineNumber: Int { get }
    
    func run(context: GRPHContext) throws
    
    var name: String { get }
    
    func toString(indent: String) -> String
}

extension Instruction {
    func safeRun(context: GRPHContext) throws {
        // TODO MANAGE ERRORS HERE
        try self.run(context: context)
    }
    
    var line: Int {
        lineNumber + 1
    }
}
