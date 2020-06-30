//
//  GRPHValue.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

/* Immutable types should be structs, mutable types should be classes */
public protocol GRPHValue {
    var type: GRPHType { get }
}

extension Int: GRPHValue {
    public var type: GRPHType { SimpleType.integer }
}

extension String: GRPHValue {
    public var type: GRPHType { SimpleType.string }
}

extension Float: GRPHValue {
    public var type: GRPHType { SimpleType.float }
}

extension Bool: GRPHValue {
    public var type: GRPHType { SimpleType.boolean }
}

extension Optional: GRPHValue where Wrapped: GRPHValue {
    public var type: GRPHType {
        switch self {
        case .none:
            return OptionalType(wrapped: SimpleType.mixed) // Type inference is done here in Java
        case .some(let value):
            return OptionalType(wrapped: value.type)
        }
    }
}
