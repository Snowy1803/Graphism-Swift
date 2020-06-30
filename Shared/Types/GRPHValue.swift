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

public protocol StatefulValue: GRPHValue {
    var state: String { get }
}

extension Int: StatefulValue {
    public var type: GRPHType { SimpleType.integer }
    public var state: String { String(self) }
}

extension String: StatefulValue {
    public var type: GRPHType { SimpleType.string }
    public var state: String { self.asLiteral }
}

extension Float: StatefulValue {
    public var type: GRPHType { SimpleType.float }
    public var state: String { "\(self)F" }
}

extension Bool: StatefulValue {
    public var type: GRPHType { SimpleType.boolean }
    public var state: String { self ? "true" : "false" }
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

extension Optional: StatefulValue where Wrapped: StatefulValue {
    public var state: String {
        switch self {
        case .none:
            return "null"
        case .some(let value):
            return value.state
        }
    }
}
