//
//  GRPHVirtualAssignmentContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/07/2020.
//

import Foundation

class GRPHVirtualAssignmentContext: GRPHContext {
    let parent: GRPHContext
    let virtualValue: GRPHValue
    
    init(parent: GRPHContext, virtualValue: GRPHValue) {
        self.parent = parent
        self.virtualValue = virtualValue
        super.init(parser: parent.parser)
    }
    
    override var allVariables: [Variable] {
        return parent.allVariables
    }
    
    override func findVariable(named name: String) -> Variable? {
        return parent.findVariable(named: name)
    }
    
    override func findVariableInScope(named name: String) -> Variable? {
        return parent.findVariableInScope(named: name)
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        return parent.addVariable(variable, global: global)
    }
    
    // Shouldn't happen but we never know what reflection functions we may add
    override func breakNearestBlock<T>(_ type: T.Type, scope: BreakInstruction.BreakScope = .scopes(1)) throws -> T where T : GRPHBlockContext {
        return try parent.breakNearestBlock(type, scope: scope)
    }
    
    override var inFunction: FunctionDeclarationBlock? { parent.inFunction }
}
