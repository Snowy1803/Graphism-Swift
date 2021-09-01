//
//  VariableDeclarationInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct VariableDeclarationInstruction: Instruction {
    static let pattern = try! NSRegularExpression(pattern: "^(global +)?(final +)?(\(Expressions.typePattern)) +([$A-Za-z_][A-Za-z0-9_]*)(?: *= *(.*))?$")
    
    let global, constant: Bool
    
    let type: GRPHType
    let name: String
    let value: Expression
    
    let lineNumber: Int
    
    init(lineNumber: Int, global: Bool, constant: Bool, type: GRPHType, name: String, value: Expression) {
        self.lineNumber = lineNumber
        self.global = global
        self.constant = constant
        self.type = type
        self.name = name
        self.value = value
    }
    
    init(lineNumber: Int, groups: [String?], context: CompilingContext) throws {
        guard groups[5] != nil else {
            throw GRPHCompileError(type: .parse, message: "A variable must have a value when it is defined")
        }
        let name = groups[4]!
        guard context.findVariableInScope(named: name) == nil else {
            throw GRPHCompileError(type: .redeclaration, message: "Invalid redeclaration of variable '\(name)'")
        }
        guard GRPHCompiler.varNameRequirement.firstMatch(string: name) != nil else {
            throw GRPHCompileError(type: .parse, message: "Invalid variable name '\(name)'")
        }
        let value: Expression
        let type: GRPHType
        if groups[3] == "auto" {
            value = try Expressions.parse(context: context, infer: nil, literal: groups[5]!)
            type = try value.getType(context: context, infer: SimpleType.mixed)
        } else if let type0 = GRPHTypes.parse(context: context, literal: groups[3]!.trimmingCharacters(in: .whitespaces)) {
            value = try GRPHTypes.autobox(context: context,
                                          expression: Expressions.parse(context: context, infer: type0, literal: groups[5]!),
                                          expected: type0)
            type = type0
            guard try type.isInstance(context: context, expression: value) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Incompatible types '\(try value.getType(context: context, infer: type))' and '\(type)' in declaration")
            }
        } else {
            throw GRPHCompileError(type: .parse, message: "Unknown type '\(groups[3]!)'")
        }
        context.addVariable(Variable(name: name, type: type, final: groups[2] != nil, compileTime: true), global: groups[1] != nil)
        self.init(lineNumber: lineNumber, global: groups[1] != nil, constant: groups[2] != nil, type: type, name: groups[4]!, value: value)
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)\(global ? "global " : "")\(constant ? "final " : "")\(type.string) \(name) = \(value.string)\n"
    }
}
