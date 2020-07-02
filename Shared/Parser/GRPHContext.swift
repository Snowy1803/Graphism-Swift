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
}

protocol GRPHParser {
    var debugging: Bool { get }
    var debugStep: TimeInterval { get }
}
