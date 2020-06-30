//
//  GRPHArray.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

class GRPHArray<Content: GRPHValue>: StatefulValue {
    var wrapped: [Content]
    var content: GRPHType
    
    init(_ wrapped: [Content] = [], of content: GRPHType) {
        self.wrapped = wrapped
        self.content = content
    }
    
    public var state: String {
        var str = "\(content.string){"
        guard !wrapped.isEmpty else {
            return "\(str)}"
        }
        for value in wrapped {
            if let value = value as? StatefulValue {
                str += "\(value.state) "
            } else {
                str += "stateless "
            }
        }
        return "\(str.dropLast())}"
    }
    
    public var type: GRPHType { ArrayType(content: content) }
}
