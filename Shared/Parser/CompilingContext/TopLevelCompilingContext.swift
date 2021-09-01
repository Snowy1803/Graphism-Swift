//
//  TopLevelCompilingContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

/// This is the only context that doesn't have a parent
class TopLevelCompilingContext: VariableOwningCompilingContext {
    
    init(compiler: GRPHCompiler) {
        super.init(compiler: compiler, parent: nil)
        variables.append(contentsOf: GRPHCompiler.defaultVariables)
    }
    
    override func assertParentNonNil() {
        
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        variables.append(variable)
    }
}
