//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

struct OptionalType: GRPHType {
    let wrapped: GRPHType
    
    var string: String {
        if wrapped is MultiOrType {
            return "<\(wrapped.string)>?"
        }
        return "\(wrapped.string)?"
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        return other is OptionalType && wrapped.isInstance(of: (other as! OptionalType).wrapped)
    }
    
    var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "wrapped", type: wrapped, optional: true)], type: self) { ctx, values in
            if values.count == 1 {
                return GRPHOptional.some(values[0]!)
            } else {
                return GRPHOptional.null
            }
        }
    }
}

struct MultiOrType: GRPHType {
    let type1, type2: GRPHType
    
    var string: String {
        "\(type1.string)|\(type2.string)"
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        return other.isTheMixed || (type1.isInstance(of: other) && type2.isInstance(of: other))
    }
}

struct ArrayType: GRPHType {
    let content: GRPHType
    
    var string: String {
        "{\(content.string)}"
    }
    
    var supertype: GRPHType {
        if content.isTheMixed {
            return SimpleType.mixed
        }
        return ArrayType(content: content.supertype)
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let array = other as? ArrayType {
            return content.isInstance(of: array.content)
        }
        return other.isTheMixed
    }
    
    var fields: [Field] {
        return [VirtualField<GRPHArray>(name: "length", type: SimpleType.integer, getter: { $0.count })]
    }
    
    var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "element", type: content, optional: true)], type: self, varargs: true) { ctx, values in
            GRPHArray(values.compactMap { $0 }, of: content)
        }
    }
    
    var includedMethods: [Method] {
        [
            Method(ns: RandomNameSpace(), name: "shuffled", inType: self, parameters: [], returnType: self) { ctx, array, values in
                return GRPHArray((array as! GRPHArray).wrapped.shuffled(), of: content)
            },
            Method(ns: StandardNameSpace(), name: "copy", inType: self, parameters: [], returnType: self) { ctx, array, values in
                return GRPHArray((array as! GRPHArray).wrapped, of: content)
            }
        ]
    }
}
