//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct Constructor: Parametrable {
    let parameters: [Parameter]
    let type: GRPHType
    let varargs: Bool
    /// The array will be populated as the parameters array, with nil for optional parameters with no given value. The only exception is at the end, where nil values will not be present;
    /// check values.count instead
    let executable: (RuntimeContext, [GRPHValue?]) -> GRPHValue
    
    init(parameters: [Parameter], type: GRPHType, varargs: Bool = false, executable: @escaping (RuntimeContext, [GRPHValue?]) -> GRPHValue) {
        self.parameters = parameters
        self.type = type
        self.varargs = varargs
        self.executable = executable
    }
    
    var name: String { type.string }
    var returnType: GRPHType { type }
}
