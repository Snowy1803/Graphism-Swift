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
    var varargs: Bool = false
    /// The array will be populated as the parameters array, with nil for optional parameters with no given value. The only exception is at the end, where nil values will not be present;
    /// check values.count instead
    var executable: (GRPHContext, [GRPHValue?]) -> GRPHValue
    
    var name: String { type.string }
    var returnType: GRPHType { type }
}
