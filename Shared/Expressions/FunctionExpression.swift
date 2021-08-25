//
//  FunctionExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct FunctionExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^([A-Za-z_>]+)\\[(.*)\\]$")
    static let instructionPattern = try! NSRegularExpression(pattern: "^([A-Za-z_>]+)(?: ([^ \\n]+))? *: *(.*)$")
    
    let function: Function
    let values: [Expression?]
    
    init(ctx: GRPHContext, function: Function, values: [Expression], asInstruction: Bool = false) throws {
        var nextParam = 0
        self.function = function
        var ourvalues: [Expression?] = []
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        for param in values {
            guard let par = try function.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: function.parameter(index: nextParam).type))' in function '\(function.name)'")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(try GRPHTypes.autobox(context: ctx, expression: param, expected: par.param.type))
            // at pars[nextParam - 1] aka current param
        }
        self.values = ourvalues
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        do {
            return try function.executable(context, try values.map { try $0?.eval(context: context) })
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(fullyQualified)")
            throw e
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        return function.returnType
    }
    
    var fullyQualified: String {
        "\(function.ns.name == "standard" || function.ns.name == "none" ? "" : "\(function.ns.name)>")\(function.name)"
    }
    
    var string: String {
        "\(fullyQualified)[\(function.formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    var needsBrackets: Bool { false }
}
