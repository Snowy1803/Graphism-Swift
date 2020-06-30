//
//  GRPHArray.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

class GRPHArray<Content: GRPHValue>: StatefulValue, GRPHArrayProtocol {
    
    var wrapped: [Content]
    var content: GRPHType
    
    init(_ wrapped: [Content] = [], of content: GRPHType) {
        self.wrapped = wrapped
        self.content = content
    }
    
    init?(byCasting value: GRPHValue) {
        if let val = value as? GRPHArray {
            self.wrapped = val.wrapped // Cast will effectively copy ≠ Java
            self.content = val.content
        } else {
            return nil
        }
    }
    
    public var state: String {
        guard !wrapped.isEmpty else {
            return "{}"
        }
        
        var str = "{"
        for value in wrapped {
            if let value = value as? StatefulValue {
                str += "\(value.state), "
            } else {
                str += "stateless, "
            }
        }
        return "\(str.dropLast(2))}"
    }
    
    var count: Int { wrapped.count }
    
    public var type: GRPHType { ArrayType(content: content) }
}

protocol GRPHArrayProtocol {
    var count: Int { get }
}
