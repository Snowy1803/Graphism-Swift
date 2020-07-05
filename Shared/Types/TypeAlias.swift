//
//  TypeAlias.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct TypeAlias: Importable {
    var name: String
    var type: GRPHType
    
    var exportedTypeAliases: [TypeAlias] { [self] }
}
