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
    
    init(parameters: [Parameter], type: GRPHType, varargs: Bool = false) {
        self.parameters = parameters
        self.type = type
        self.varargs = varargs
    }
    
    var name: String { type.string }
    var returnType: GRPHType { type }
}
