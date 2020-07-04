//
//  Parametrable.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

protocol Parametrable {
    var parameters: [Parameter] { get }
    
    var name: String { get }
    
    var returnType: GRPHType? { get }
    
    var varargs: Bool { get }
}

extension Parametrable {
    
    func parameter(index: Int) -> Parameter {
        if varargs && index >= parameters.count {
            return parameters[parameters.count - 1]
        }
        return parameters[index]
    }
    
    func parameter(index: Int, context: GRPHContext, exp: Expression) throws -> (param: Parameter, add: Int)? {
        var param = index
        while param < maximumParameterCount {
            let curr = parameter(index: param)
            let type = try exp.getType(context: context, infer: curr.type)
            if type.isInstance(of: curr.type) {
                return (param: curr, add: param - index + 1)
            } else if curr.type.isInstance(of: SimpleType.shape) && type as? SimpleType == SimpleType.shape {
                return (param: curr, add: param - index + 1) // Backwards compatibility
            } else if !curr.optional {
                return nil // missing
            }
            param += 1
        }
        return nil
    }
    
    var minimumParameterCount: Int {
        parameters.filter { $0.optional }.count
    }
    
    var maximumParameterCount: Int {
        varargs ? Int.max : parameters.count
    }
    
    func formattedParameterList(values: [Expression]) -> String {
        values.map { $0.bracketized }.joined(separator: " ")
    }
}
