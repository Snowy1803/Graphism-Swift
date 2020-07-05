//
//  FunctionExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct FunctionExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^([A-Za-z>]+)\\[(.*)\\]$")
    
    var function: Function
    var values: [Expression]
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        do {
            var pars = [GRPHValue?]()
            var nextParam = 0
            for param in values {
                let val = try param.eval(context: context)
                guard let par = try function.parameter(index: nextParam, context: context, exp: param) else {
                    throw GRPHRuntimeError(type: .unexpected, message: "Unknown parameter '\(param.string)' in function call \(function.name)")
                }
                nextParam += par.add
                while pars.count < nextParam - 1 {
                    pars.append(nil)
                }
                pars.append(val) // at pars[nextParam - 1] aka current param
            }
            return try function.executable(context, pars)
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(fullyQualified)")
            throw e
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        return function.type
    }
    
    var fullyQualified: String {
        "\(function.ns.name == "standard" || function.ns.name == "none" ? "" : "\(function.ns.name)>")\(function.name)"
    }
    
    var string: String {
        "\(fullyQualified)[\(function.formattedParameterList(values: values))]"
    }
    
    var needsBrackets: Bool { false }
}
