//
//  GRPHVariableOwningContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

class GRPHVariableOwningContext: GRPHContext {
    
    let parent: GRPHContext
    
    var variables: [Variable] = []
    
    init(parent: GRPHContext) {
        self.parent = parent
        super.init(parser: parent.parser)
    }
    
    deinit {
        if runtime?.debugging ?? false {
            for variable in variables {
                printout("[DEBUG -VAR \(variable.name)]")
            }
        }
    }
    
    override var allVariables: [Variable] {
        var vars = parent.allVariables
        vars.append(contentsOf: variables)
        return vars
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return parent.findVariable(named: name)
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    override func findVariableInScope(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return nil
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        if global {
            parser.globalVariables.append(variable)
        } else {
            variables.append(variable)
        }
    }
}
