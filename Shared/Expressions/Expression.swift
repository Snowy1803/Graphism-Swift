//
//  Expression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

protocol Expression {
    
    func eval(context: GRPHContext) throws -> GRPHValue
    
    var string: String { get }
    
    var needsBrackets: Bool { get }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType
}

struct Expressions {
    static let typePattern = try! NSRegularExpression(pattern: "[A-Za-z|<>{}?]+")
    
    private init() {}
    
    static func parse(context: GRPHContext, infer: GRPHType, literal str: String) throws -> Expression {
        // TODO
        throw GRPHCompileError(type: .parse, message: "Could not parse expression '\(str)'")
    }
}
