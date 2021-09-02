//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

extension Constructor {
    @available(*, deprecated)
    init(parameters: [Parameter], type: GRPHType, varargs: Bool = false, executable: @escaping (RuntimeContext, [GRPHValue?]) -> GRPHValue) {
        self.init(parameters: parameters, type: type, varargs: varargs, storage: .native)
        NativeFunctionRegistry.shared.implement(constructor: self) { type, ctx, args in
            executable(ctx, args)
        }
    }
    
    func execute(context: RuntimeContext, arguments: [GRPHValue?]) -> GRPHValue {
        NativeFunctionRegistry.shared.implementation(for: self)(type, context, arguments)
    }
}
