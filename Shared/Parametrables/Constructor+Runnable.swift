//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

extension Constructor {
    func execute(context: RuntimeContext, arguments: [GRPHValue?]) -> GRPHValue {
        NativeFunctionRegistry.shared.implementation(for: self)(type, context, arguments)
    }
}
