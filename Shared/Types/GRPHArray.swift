//
//  GRPHArray.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

class GRPHArray<Content: GRPHValue>: GRPHValue {
    var wrapped: [Content]
    var content: GRPHType
    
    init(_ wrapped: [Content] = [], of content: GRPHType) {
        self.wrapped = wrapped
        self.content = content
    }
    
    public var type: GRPHType { ArrayType(content: content) }
}
