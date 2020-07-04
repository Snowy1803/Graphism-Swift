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
    var value: Expression? = nil
    
    func run(context: GRPHContext) throws {
        switch type {
        case .break:
            try context.breakBlock()
        case .continue:
            try context.continueBlock()
        case .return:
            // ADD try context.returnFunction(value.eval(context)!)
            break
        }
    }
    
    func toString(indent: String) -> String {
        return "\(line):\(indent)#\(type.rawValue)\(value == nil ? "" : " \(value!.string)")\n"
    }
    
    enum BreakType: String {
        case `break` = "break"
        case `continue` = "continue"
        case `return` = "return"
    }
}


