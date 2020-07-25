//
//  Function.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct Function: Parametrable, Importable {
    let ns: NameSpace
    let name: String
    let parameters: [Parameter]
    let returnType: GRPHType
    let varargs: Bool
    let executable: (GRPHContext, [GRPHValue?]) throws -> GRPHValue
    
    init(ns: NameSpace, name: String, parameters: [Parameter], returnType: GRPHType = SimpleType.void, varargs: Bool = false, executable: @escaping (GRPHContext, [GRPHValue?]) throws -> GRPHValue) {
        self.ns = ns
        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.varargs = varargs
        self.executable = executable
    }
    
    var exportedFunctions: [Function] { [self] }
}

extension Function {
    init?(imports: [Importable], namespace: NameSpace, name: String) {
        if namespace.isEqual(to: NameSpaces.none) {
            for imp in imports {
                if let found = imp.exportedFunctions.first(where: { $0.name == name }) {
                    self = found
                    return
                }
            }
        } else if let found = namespace.exportedFunctions.first(where: { $0.name == name }) {
            self = found
            return
        }
        return nil
    }
}
