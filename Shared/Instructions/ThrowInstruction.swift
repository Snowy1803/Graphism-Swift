//
//  ThrowInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct ThrowInstruction: Instruction {
    let lineNumber: Int
    let type: GRPHRuntimeError.RuntimeExceptionType
    let message: Expression
    
    func run(context: GRPHContext) throws {
        throw GRPHRuntimeError(type: type, message: try message.eval(context: context) as! String)
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)#throw \(type.rawValue)Exception(\(message))\n"
    }
}
