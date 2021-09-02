//
//  Method.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation

extension Method {
    @available(*, deprecated)
    init(ns: NameSpace, name: String, inType: GRPHType, final: Bool = false, parameters: [Parameter], returnType: GRPHType = SimpleType.void, varargs: Bool = false, executable: @escaping (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        
        self.init(ns: ns, name: name, inType: inType, final: final, parameters: parameters, returnType: returnType, varargs: varargs, storage: .native)
        NativeFunctionRegistry.shared.implement(method: self, with: executable)
    }
    
    func execute(context: RuntimeContext, on: GRPHValue, arguments: [GRPHValue?]) throws -> GRPHValue {
        switch storage {
        case .native:
            return try NativeFunctionRegistry.shared.implementation(for: self)(context, on, arguments)
        }
    }
}
