//
//  GRPHFunctionContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

class GRPHFunctionContext: GRPHBlockContext {
    var currentReturnValue: GRPHValue?
    
    init(parent: GRPHContext, function: FunctionDeclarationBlock) {
        super.init(parent: parent, block: function)
    }
    
    override var allVariables: [Variable] {
        var vars = parser.globalVariables.filter { $0.final }
        vars.append(contentsOf: variables)
        return vars
    }
    
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return parser.globalVariables.first(where: { $0.name == name && $0.final })
    }
    
    func setReturnValue(returnValue: GRPHValue?) throws {
        currentReturnValue = returnValue // type checked at compile time
    }
    
    override var inFunction: FunctionDeclarationBlock? { (block as! FunctionDeclarationBlock) }
}
