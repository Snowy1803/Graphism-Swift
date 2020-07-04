//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct Constructor: Parametrable {
    var parameters: [Parameter]
    var type: GRPHType
    var varargs: Bool
    var executable: (GRPHContext, [GRPHValue?]) -> GRPHValue
    
    var name: String { type.string }
    var returnType: GRPHType? { type }
}
