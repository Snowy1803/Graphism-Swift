//
//  GRPHOptional.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

// A type-erased Optional, used in GRPH
enum GRPHOptional: GRPHValue {
    
    case null
    case some(GRPHValue)
    
    var type: GRPHType {
        switch self {
        case .null:
            return OptionalType(wrapped: SimpleType.mixed) // Type inference is done in GRPHType.realType(of:expected:)
        case .some(let value):
            return OptionalType(wrapped: value.type)
        }
    }
    
    var isEmpty: Bool {
        switch self {
        case .null:
            return true
        case .some(_):
            return false
        }
    }
}