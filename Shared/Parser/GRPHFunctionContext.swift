//
//  GRPHFunctionContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

class GRPHFunctionContext: GRPHContext {
    init(parent: GRPHContext, function: FunctionDeclarationBlock) {
        super.init(parent: parent)
        inBlock(block: function)
    }
    
    override var allVariables: [Variable] {
        var vars = parser.globalVariables.filter { $0.final }
        for scope in blocks {
            vars.append(contentsOf: scope.variables)
        }
        return vars
    }
    
    override func findVariable(named name: String) -> Variable? {
        for scope in blocks.reversed() {
            if let found = scope.variables.first(where: { $0.name == name }) {
                return found
            }
        }
        return parser.globalVariables.first(where: { $0.name == name && $0.final })
    }
}
