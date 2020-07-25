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
    var scope: BreakScope
    
    func run(context: GRPHContext) throws {
        switch type {
        case .break:
            try context.breakBlock(scope: scope)
        case .continue:
            try context.continueBlock(scope: scope)
        case .fall:
            try context.fallFromBlock(scope: scope)
        case .fallthrough:
            try context.fallthroughNextBlock(scope: scope)
        }
    }
    
    func toString(indent: String) -> String {
        return "\(line):\(indent)#\(type.rawValue) \(scope)\n"
    }
    
    enum BreakType: String {
        case `break` = "break"
        case `continue` = "continue"
        case fall = "fall"
        case `fallthrough` = "fallthrough"
    }
    
    enum BreakScope: CustomStringConvertible {
        case scopes(Int)
        case label(String)
        
        static func parse(params: String) throws -> BreakScope {
            if params.hasPrefix("::") {
                return .label(String(params.dropFirst(2)))
            } else if let i = Int(params) {
                return .scopes(i)
            } else if params.isEmpty {
                return .scopes(1)
            } else {
                throw GRPHCompileError(type: .parse, message: "Break instruction expected a label or a number of scopes")
            }
        }
        
        var description: String {
            switch self {
            case .scopes(let n):
                return "\(n)"
            case .label(let label):
                return "::\(label)"
            }
        }
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
