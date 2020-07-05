//
//  StandardNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct StandardNameSpace: NameSpace {
    var name: String { "standard" }
    
    var exportedTypes: [GRPHType] {
        SimpleType.allCases
    }
    
    var exportedTypeAliases: [TypeAlias] {
        [
            TypeAlias(name: "farray", type: ArrayType(content: SimpleType.float)),
            TypeAlias(name: "int", type: SimpleType.integer),
            TypeAlias(name: "Square", type: SimpleType.Rectangle),
            TypeAlias(name: "Rect", type: SimpleType.Rectangle),
            TypeAlias(name: "R", type: SimpleType.Rectangle),
            TypeAlias(name: "Ellipse", type: SimpleType.Circle),
            TypeAlias(name: "E", type: SimpleType.Circle),
            TypeAlias(name: "C", type: SimpleType.Circle),
            TypeAlias(name: "L", type: SimpleType.Line),
            TypeAlias(name: "Poly", type: SimpleType.Polygon),
            TypeAlias(name: "P", type: SimpleType.Polygon),
            TypeAlias(name: "T", type: SimpleType.Text),
            TypeAlias(name: "G", type: SimpleType.Group),
            TypeAlias(name: "Back", type: SimpleType.Background)
        ]
    }
}
