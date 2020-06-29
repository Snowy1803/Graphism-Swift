//
//  Pos.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public struct Pos: GRPHType {
    var x: Int
    var y: Int
    
    var state: String {
        "\(x),\(y)"
    }
    
    var square: Bool {
        x == y
    }
}
