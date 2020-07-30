//
//  MethodExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation

struct MethodExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.*?)\\.([A-Za-z>]+)\\[(.*)\\]$")
    //static let instructionPattern = try! NSRegularExpression(pattern: "^([A-Za-z>]+)(?: ([^ \\n]+))? *: *(.*)$")
    
    let method: Method
    let on: Expression
    let values: [Expression?]
    
    init(ctx: GRPHContext, method: Method, on: Expression, values: [Expression], asInstruction: Bool = false) throws {
        var nextParam = 0
        self.method = method
        self.on = on
        var ourvalues: [Expression?] = []
        guard asInstruction || !method.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        for param in values {
            guard let par = try method.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: SimpleType.mixed))' in method '\(method.inType)>\(method.name)'")
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
        let onValue = try on.eval(context: context)
        var m = method
        if !m.effectivelyFinal { // check for overrides
            let real = GRPHTypes.type(of: onValue, expected: m.inType)
            m = Method(imports: context.parser.imports, namespace: NameSpaces.none, name: m.name, inType: real) ?? m
        }
        do {
            return try m.executable(context, onValue, try values.map { try $0?.eval(context: context) })
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(fullyQualified)")
            throw e
        }
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        return method.returnType
    }
    
    var fullyQualified: String {
        "\(method.ns.name == "standard" || method.ns.name == "none" ? "" : "\(method.ns.name)>")\(method.name)"
    }
    
    var string: String {
        "\(on).\(fullyQualified)[\(method.formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    var needsBrackets: Bool { false }
}
