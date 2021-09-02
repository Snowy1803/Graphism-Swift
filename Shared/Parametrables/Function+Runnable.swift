//
//  Function.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

extension Function {
    @available(*, deprecated)
    init(ns: NameSpace, name: String, parameters: [Parameter], returnType: GRPHType = SimpleType.void, varargs: Bool = false, executable: @escaping (RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
        
        self.init(ns: ns, name: name, parameters: parameters, returnType: returnType, varargs: varargs, storage: .native)
        NativeFunctionRegistry.shared.implement(function: self, with: executable)
    }
    
    func execute(context: RuntimeContext, arguments: [GRPHValue?]) throws -> GRPHValue {
        switch storage {
        case .native:
            return try NativeFunctionRegistry.shared.implementation(for: self)(context, arguments)
        case .block(let block):
            return try block.executeFunction(context: context, params: arguments)
        }
    }
}
