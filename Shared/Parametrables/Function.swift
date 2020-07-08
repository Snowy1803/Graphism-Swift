//
//  Function.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct Function: Parametrable, Importable {
    var ns: NameSpace
    var name: String
    var parameters: [Parameter]
    var returnType: GRPHType?
    var varargs: Bool = false
    var executable: (GRPHContext, [GRPHValue?]) throws -> GRPHValue
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
