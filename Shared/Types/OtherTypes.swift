//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public struct OptionalType: GRPHType {
    var wrapped: GRPHType
    
    public var string: String {
        if wrapped is MultiOrType {
            return "<\(wrapped.string)>?"
        }
        return "\(wrapped.string)?"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        return other is OptionalType && wrapped.isInstance(of: (other as! OptionalType).wrapped)
    }
}

public struct MultiOrType: GRPHType {
    var type1, type2: GRPHType
    
    public var string: String {
        "\(type1.string)|\(type2.string)"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        return other.isTheMixed || (type1.isInstance(of: other) && type2.isInstance(of: other))
    }
}

public struct ArrayType: GRPHType {
    var content: GRPHType
    
    public var string: String {
        "{\(content.string)}"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let array = other as? ArrayType {
            return content.isInstance(of: array.content)
        }
        return other.isTheMixed
    }
    
    public var fields: [Field] {
        return [VirtualField<GRPHArray>(name: "length", type: SimpleType.integer, getter: { $0.count })]
    }
}
