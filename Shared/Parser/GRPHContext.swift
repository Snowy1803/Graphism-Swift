//
//  GRPHContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

class GRPHContext {
    // Strong reference. Makes it a circular reference. As long as the script is running, this is not a problem. When the script is terminated, context is always deallocated, so the circular reference is broken.
    let parser: GRPHParser
    var last: GRPHContext?
    
    var compiler: GRPHCompiler? {
        parser as? GRPHCompiler
    }
    
    var runtime: GRPHRuntime? {
        parser as? GRPHRuntime
    }
    
    init(parser: GRPHParser) {
        self.parser = parser
    }
    
    var allVariables: [Variable] {
        return parser.globalVariables
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    func findVariable(named name: String) -> Variable? {
        return parser.globalVariables.first(where: { $0.name == name })
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    func findVariableInScope(named name: String) -> Variable? {
        return parser.globalVariables.first(where: { $0.name == name })
    }
    
    func addVariable(_ variable: Variable, global: Bool) {
        parser.globalVariables.append(variable)
    }
    
    final func breakBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(GRPHBlockContext.self, scope: scope)
    }
    
    final func continueBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(GRPHBlockContext.self, scope: scope).continueBlock()
    }
    
    final func fallFromBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(GRPHBlockContext.self, scope: scope).fallFrom()
    }
    
    final func fallthroughNextBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(GRPHBlockContext.self, scope: scope).fallthroughNext()
    }
    
    final func returnFunction(returnValue: GRPHValue?) throws {
        try breakNearestBlock(GRPHFunctionContext.self).setReturnValue(returnValue: returnValue)
    }
    
    @discardableResult func breakNearestBlock<T: GRPHBlockContext>(_ type: T.Type, scope: BreakInstruction.BreakScope = .scopes(1)) throws -> T {
        throw GRPHRuntimeError(type: .unexpected, message: "Couldn't break out")
    }
    
    var inFunction: FunctionDeclarationBlock? { nil }
}

protocol GRPHParser: AnyObject {
    var globalVariables: [Variable] { get set }
    var imports: [Importable] { get }
}
