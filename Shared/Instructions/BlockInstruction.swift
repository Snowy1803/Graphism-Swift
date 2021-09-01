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
    
    @discardableResult func createContext(_ context: inout RuntimeContext) -> BlockRuntimeContext
    
    @discardableResult func createContext(_ context: inout CompilingContext) -> BlockCompilingContext
    
    func run(context: inout RuntimeContext) throws
    
    func mustRun(context: BlockRuntimeContext) -> Bool
    
    func canRun(context: BlockRuntimeContext) throws -> Bool
    
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
    
    @discardableResult func createContext(_ context: inout RuntimeContext) -> BlockRuntimeContext {
        let ctx = BlockRuntimeContext(parent: context, block: self)
        context = ctx
        return ctx
    }
    
    @discardableResult func createContext(_ context: inout CompilingContext) -> BlockCompilingContext {
        let ctx = BlockCompilingContext(compiler: context.compiler, parent: context)
        context = ctx
        return ctx
    }
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        if try mustRun(context: ctx) || canRun(context: ctx) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
    
    func mustRun(context: BlockRuntimeContext) -> Bool {
        if let last = context.parent?.previous as? BlockRuntimeContext,
           last.mustNextRun {
            last.mustNextRun = false
            return true
        }
        return false
    }
    
    func runChildren(context: BlockRuntimeContext) throws {
        context.canNextRun = false
        var last: RuntimeContext?
        var i = 0
        while i < children.count && !context.broken && !Thread.current.isCancelled {
            let child = children[i]
            context.previous = last
            let runtime = context.runtime
            if runtime.debugging {
                printout("[DEBUG LOC \(child.line)]")
            }
            if runtime.image.destroyed {
                throw GRPHExecutionTerminated()
            }
            if runtime.debugStep > 0 {
                _ = runtime.debugSemaphore.wait(timeout: .now() + runtime.debugStep)
            }
            var inner: RuntimeContext = context
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
    
    init(context: inout CompilingContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    var name: String { "block" }
    
    func canRun(context: BlockRuntimeContext) throws -> Bool { true }
}
