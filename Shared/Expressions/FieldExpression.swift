//
//  FieldExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct FieldExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.+)\\.([A-Za-z0-9_]+)$")
    
    var on: Expression
    var field: Field
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        field.getValue(on: try on.eval(context: context))
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        field.type
    }
    
    var string: String {
        "\(on.bracketized).\(field.name)"
    }
    
    var needsBrackets: Bool { false }
}

struct ConstantPropertyExpression: Expression {
    var property: TypeConstant
    var inType: GRPHType
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        property.value
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        property.type
    }
    
    var string: String {
        "\(inType.string).\(property.name)"
    }
    
    var needsBrackets: Bool { false }
}
