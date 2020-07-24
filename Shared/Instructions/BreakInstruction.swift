//
//  BreakInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct BreakInstruction: Instruction {
    var lineNumber: Int
    var type: BreakType
    
    func run(context: GRPHContext) throws {
        switch type {
        case .break:
            try context.breakBlock()
        case .continue:
            try context.continueBlock()
        }
    }
    
    func toString(indent: String) -> String {
        return "\(line):\(indent)#\(type.rawValue)\n"
    }
    
    enum BreakType: String {
        case `break` = "break"
        case `continue` = "continue"
    }
}

struct ReturnInstruction: Instruction {
    var lineNumber: Int
    var value: Expression? = nil
    
    func run(context: GRPHContext) throws {
        try context.returnFunction(returnValue: value?.eval(context: context))
    }
    
    func toString(indent: String) -> String {
        return "\(line):\(indent)#return \(value?.string ?? "")\n"
    }
}
