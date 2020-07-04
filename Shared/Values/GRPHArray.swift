//
//  GRPHArray.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

class GRPHArray: StatefulValue, GRPHArrayProtocol {
    
    var wrapped: [GRPHValue]
    var content: GRPHType
    
    init(_ wrapped: [GRPHValue] = [], of content: GRPHType) {
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
    
    func isEqualTo(_ other: GRPHValue) -> Bool {
        if let other = other as? GRPHArray,
           other.count == self.count {
            if self === other {
                return true
            }
            for i in 0..<self.count {
                if self.wrapped[i].isEqualTo(other.wrapped[i]) {
                    return false
                }
            }
            return true
        }
        return false
    }
}

protocol GRPHArrayProtocol {
    var count: Int { get }
}
