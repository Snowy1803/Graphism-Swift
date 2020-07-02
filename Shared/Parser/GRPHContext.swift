//
//  GRPHContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

class GRPHContext {
    var parent: GRPHContext?
    var parser: GRPHParser
    var last: Instruction?
    var blocks: [BlockInstruction] = []
    
    init(parser: GRPHParser) {
        self.parser = parser
    }
    
    init(parent: GRPHContext) {
        self.parser = parent.parser
        self.parent = parent
    }
    
    func inBlock(block: BlockInstruction) {
        blocks.append(block)
    }
    
    func closeBlock() {
        let closed = blocks.removeLast()
        if parser.debugging {
            for variable in closed.variables {
                print("[DEBUG -VAR \(variable.name)]")
            }
        }
    }
    
    var allVariables: [Variable] {
        var vars = parser.globalVariables
        for scope in blocks {
            vars.append(contentsOf: scope.variables)
        }
        if let parent = parent {
            for scope in parent.blocks {
                vars.append(contentsOf: scope.variables)
            }
        }
        return vars
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    func findVariable(named name: String) -> Variable? {
        for scope in blocks.reversed() {
            if let found = scope.variables.first(where: { $0.name == name }) {
                return found
            }
        }
        if let parent = parent {
            return parent.findVariable(named: name)
        }
        // Top level
        return parser.globalVariables.first(where: { $0.name == name })
    }
    
    func addVariable(_ variable: Variable, global: Bool) {
        if global || blocks.isEmpty { // Note that blocks is never empty in function scope
            parser.globalVariables.append(variable)
        } else {
            blocks.last!.variables.append(variable)
        }
    }
}

protocol GRPHParser {
    var debugging: Bool { get }
    var debugStep: TimeInterval { get }
    var globalVariables: [Variable] { get set }
}