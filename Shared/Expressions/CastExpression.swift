//
//  CastExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct CastExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.+) (as|is) (\(Expressions.typePattern))$")
    
    var from: Expression
    var cast: Bool
    var to: GRPHType
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        if cast {
            fatalError("TODO")
        } else {
            return GRPHTypes.type(of: try from.eval(context: context)).isInstance(of: to)
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        cast ? to : SimpleType.boolean
    }
    
    var string: String { "\(from.string) \(cast ? "as" : "is") \(to.string)" }
    
    var needsBrackets: Bool { true }
}
