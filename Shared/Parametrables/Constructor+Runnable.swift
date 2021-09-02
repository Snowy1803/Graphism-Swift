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
        self.init(parameters: parameters, type: type, varargs: varargs)
        NativeFunctionRegistry.shared.implement(constructor: self, with: executable)
    }
    
    func execute(context: RuntimeContext, arguments: [GRPHValue?]) -> GRPHValue {
        NativeFunctionRegistry.shared.implementation(for: self)(context, arguments)
    }
}
