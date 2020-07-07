//
//  BlockInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

/// The #block instruction, but also the base class for all other blocks
class BlockInstruction: Instruction {
    var children: [Instruction] = []
    var variables: [Variable] = []
    var lineNumber: Int
    /// true if the next else can run, false otherwise
    var canNextRun: Bool = true
    /// true if #break or #continue was called in this block
    var broken: Bool = false
    /// true if #continue was caled in this block
    var continued: Bool = false
    
    init(lineNumber: Int) {
        self.lineNumber = lineNumber
    }
    
    func run(context: GRPHContext) throws {
        canNextRun = true
        broken = false
        if try canRun(context: context) {
            variables.removeAll()
            try runChildren(context: context)
        }
    }
    
    func runChildren(context: GRPHContext) throws {
        var last: Instruction?
        context.inBlock(block: self)
        defer {
            context.closeBlock()
        }
        var i = 0
        while i < children.count && !broken && !Thread.current.isCancelled {
            let child = children[i]
            context.last = last
            let runtime = context.runtime
            if runtime?.debugging ?? false {
                print("[DEBUG LOC \(child.line)]")
            }
            if runtime?.debugStep ?? 0 > 0 {
                _ = runtime?.debugSemaphore.wait(timeout: .now() + (runtime?.debugStep ?? 0))
            }
            try child.safeRun(context: context)
            last = child
            i += 1
        }
        if continued {
            broken = false
            continued = false
        }
        canNextRun = false
    }
    
    func canRun(context: GRPHContext) throws -> Bool { true }
    
    func toString(indent: String) -> String {
        var builder = "\(line):\(indent)#\(name)\n"
        for child in children {
            builder += child.toString(indent: "\(indent)\t")
        }
        return builder
    }
    
    var name: String { "block" }
    
    func breakBlock() {
        broken = true
    }
    
    func continueBlock() {
        broken = true
        continued = true
    }
}
