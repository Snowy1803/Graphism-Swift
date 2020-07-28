//
//  GRPHVirtualAssignmentContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/07/2020.
//

import Foundation

class DelegatingContext: GRPHContext {
    let parent: GRPHContext
    
    init(parent: GRPHContext) {
        self.parent = parent
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
    
    override func breakNearestBlock<T>(_ type: T.Type, scope: BreakInstruction.BreakScope = .scopes(1)) throws -> T where T : GRPHBlockContext {
        return try parent.breakNearestBlock(type, scope: scope)
    }
    
    override var inFunction: FunctionDeclarationBlock? { parent.inFunction }
}

class GRPHVirtualAssignmentContext: DelegatingContext {
    let virtualValue: GRPHValue
    
    init(parent: GRPHContext, virtualValue: GRPHValue) {
        self.virtualValue = virtualValue
        super.init(parent: parent)
    }
}

class SwitchContext: DelegatingContext {
    let compare: VariableExpression
    var state: SwitchState = .first
    
    init(parent: GRPHContext, compare: VariableExpression) {
        self.compare = compare
        super.init(parent: parent)
    }
    
    override func accepts(instruction: Instruction) throws {
        guard instruction is IfBlock
           || instruction is ElseIfBlock
           || instruction is ElseBlock else {
            throw GRPHCompileError(type: .parse, message: "Expected #case or #default in #switch block")
        }
    }
    
    enum SwitchState {
        /// Put an #if
        case first
        /// Put an #elseif or an #else
        case next
        /// Throw an error, no more cases can be added
        case last
    }
}
