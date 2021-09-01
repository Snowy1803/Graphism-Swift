//
//  FunctionRuntimeContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

class FunctionRuntimeContext: BlockRuntimeContext {
    var currentReturnValue: GRPHValue?
    
    init(parent: RuntimeContext, function: FunctionDeclarationBlock) {
        super.init(parent: parent, block: function)
    }
    
    override var allVariables: [Variable] {
        var vars = parent!.allVariables.filter { $0.final }
        vars.append(contentsOf: variables)
        return vars
    }
    
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        if let outer = parent?.findVariable(named: name), outer.final {
            return outer
        }
        return nil
    }
    
    func setReturnValue(returnValue: GRPHValue?) throws {
        currentReturnValue = returnValue // type checked at compile time
    }
}
