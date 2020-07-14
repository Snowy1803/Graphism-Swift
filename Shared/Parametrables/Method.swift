//
//  Method.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation

struct Method: Parametrable, Importable {
    var ns: NameSpace
    var name: String
    /// In this version, inType cannot be a MultiOrType. Create two methods with the same name in the respective types.
    var inType: GRPHType
    var final: Bool = false
    var parameters: [Parameter]
    var returnType: GRPHType? // new in GRPH 1.11, methods can be called with on.name[] syntax
    var varargs: Bool = false
    var executable: (GRPHContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue
    
    /// If true, runtime type checks are skipped
    var effectivelyFinal: Bool {
        final || inType.final
    }
    
    var exportedMethods: [Method] { [self] }
}

extension Method {
    init?(imports: [Importable], namespace: NameSpace, name: String, inType: GRPHType) {
        if namespace.isEqual(to: NameSpaces.none) {
            for imp in imports {
                if let found = imp.exportedMethods.first(where: { $0.name == name && $0.inType.string == inType.string }) {
                    self = found
                    return
                }
            }
        } else if let found = namespace.exportedMethods.first(where: { $0.name == name && $0.inType.string == inType.string  }) {
            self = found
            return
        }
        if inType.isTheMixed {
            return nil
        }
        self.init(imports: imports, namespace: namespace, name: name, inType: inType.supertype)
    }
}
