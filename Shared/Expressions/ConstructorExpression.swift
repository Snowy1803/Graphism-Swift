//
//  ConstructorExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct ConstructorExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(\(Expressions.typePattern))?\\((.*)\\)$")
    let constructor: Constructor
    let values: [Expression?]
    
    init(ctx: GRPHContext, type: GRPHType, values: [Expression]) throws {
        guard let constructor = type.constructor else {
            throw GRPHCompileError(type: .typeMismatch, message: "No constructor found in '\(type)'");
        }
        self.constructor = constructor
        // Java did kinda support multiple constructor but they didn't exist
        var nextParam = 0
        var ourvalues: [Expression?] = []
        for param in values {
            guard let par = try constructor.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: constructor.parameter(index: nextParam).type))' in constructor for '\(type.string)'")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(param) // at pars[nextParam - 1] aka current param
        }
        self.values = ourvalues
    }
    
    init(ctx: GRPHContext, boxing: Expression, infer: GRPHType) throws {
        self.constructor = try boxing.getType(context: ctx, infer: infer).optional.constructor!
        self.values = [boxing]
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        return constructor.executable(context, try values.map { try $0?.eval(context: context) })
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        constructor.type
    }
    
    var string: String {
        "\(constructor.type.string)(\(constructor.formattedParameterList(values: values.compactMap {$0})))"
    }
    
    var needsBrackets: Bool { false }
}
