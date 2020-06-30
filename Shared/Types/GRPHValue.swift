//
//  GRPHValue.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

/* Immutable types should be structs, mutable types should be classes */
public protocol GRPHValue {
    
}

extension Int: GRPHValue {
    
}

extension String: GRPHValue {
    
}

extension Float: GRPHValue {
    
}

extension Bool: GRPHValue {
    
}
