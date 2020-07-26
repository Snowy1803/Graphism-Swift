//
//  BlockInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

/// The #block instruction, but also the base class for all other blocks
protocol BlockInstruction: Instruction {
    var children: [Instruction] { get set }
    var label: String? { get set }
    
    @discardableResult func createContext(_ context: inout GRPHContext) -> GRPHBlockContext
    
    func run(context: inout GRPHContext) throws
    
    func mustRun(context: GRPHBlockContext) -> Bool
    
    func canRun(context: GRPHBlockContext) throws -> Bool
    
    var name: String { get }
}

extension BlockInstruction {
    func toString(indent: String) -> String {
        var builder = "\(line):\(indent)#\(name)\n"
        if let label = label {
            builder = "\(line - 1):\(indent)::\(label)\n\(builder)"
        }
        for child in children {
            builder += child.toString(indent: "\(indent)\t")
        }
        return builder
    }
    
    @discardableResult func createContext(_ context: inout GRPHContext) -> GRPHBlockContext {
        let ctx = GRPHBlockContext(parent: context, block: self)
        context = ctx
        return ctx
    }
    
    func run(context: inout GRPHContext) throws {
        let ctx = createContext(&context)
        if try mustRun(context: ctx) || canRun(context: ctx) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
    
    func mustRun(context: GRPHBlockContext) -> Bool {
        if let last = context.parent.last as? GRPHBlockContext,
           last.mustNextRun {
            last.mustNextRun = false
            return true
        }
        return false
    }
    
    func runChildren(context: GRPHBlockContext) throws {
        context.canNextRun = false
        var last: GRPHContext?
        var i = 0
        while i < children.count && !context.broken && !Thread.current.isCancelled {
            let child = children[i]
            context.last = last
            let runtime = context.runtime
            if runtime?.debugging ?? false {
                printout("[DEBUG LOC \(child.line)]")
            }
            if runtime?.image.destroyed ?? false {
                throw GRPHExecutionTerminated()
            }
            if runtime?.debugStep ?? 0 > 0 {
                _ = runtime?.debugSemaphore.wait(timeout: .now() + (runtime?.debugStep ?? 0))
            }
            var inner: GRPHContext = context
            try child.safeRun(context: &inner)
            if inner !== context {
                last = inner
            } else {
                last = nil
            }
            i += 1
        }
        if context.continued {
            context.broken = false
            context.continued = false
        }
    }
}

struct SimpleBlockInstruction: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    init(context: inout GRPHContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    var name: String { "block" }
    
    func canRun(context: GRPHBlockContext) throws -> Bool { true }
}
