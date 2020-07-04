//
//  ConstructorExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct ConstructorExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(\(Expressions.typePattern))\\((.+)\\)$")
    var constructor: Constructor
    var values: [Expression]
    
    init(ctx: GRPHContext, type: GRPHType, values: [Expression]) throws {
        self.values = values
        guard let constructor = type.constructor else {
            throw GRPHCompileError(type: .typeMismatch, message: "No constructor found in '\(type)'");
        }
        self.constructor = constructor
        // Java did kinda support multiple constructor but they didn't exist
        var nextParam = 0
        for param in values {
            guard let par = try constructor.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: constructor.parameter(index: nextParam).type))' in constructor for '\(type.string)'")
            }
            nextParam += par.add
        }
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        var pars = [GRPHValue?]()
        var nextParam = 0
        for param in values {
            let val = try param.eval(context: context)
            guard let par = try constructor.parameter(index: nextParam, context: context, exp: param) else {
                throw GRPHRuntimeError(type: .unexpected, message: "Unknown parameter '\(param.string)' in constructor")
            }
            nextParam += par.add
            while pars.count < nextParam - 1 {
                pars.append(nil)
            }
            pars.append(val) // at pars[nextParam - 1] aka current param
        }
        return constructor.executable(context, pars)
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        constructor.type
    }
    
    var string: String {
        "\(constructor.type.string)(\(constructor.formattedParameterList(values: values)))"
    }
    
    var needsBrackets: Bool { false }
}
