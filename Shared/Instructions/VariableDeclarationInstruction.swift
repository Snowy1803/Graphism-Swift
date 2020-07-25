//
//  VariableDeclarationInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

class VariableDeclarationInstruction: Instruction {
    static let pattern = try! NSRegularExpression(pattern: "^(global +)?(final +)?(\(Expressions.typePattern)) +([$A-Za-z_][A-Za-z0-9_]*)(?: *= *(.*))?$")
    
    let global, constant: Bool
    
    let type: GRPHType
    let name: String
    let value: Expression? // nil for fields in #type
    
    let lineNumber: Int
    
    init(lineNumber: Int, global: Bool, constant: Bool, type: GRPHType, name: String, value: Expression) {
        self.lineNumber = lineNumber
        self.global = global
        self.constant = constant
        self.type = type
        self.name = name
        self.value = value
    }
    
    convenience init(lineNumber: Int, groups: [String?], context: GRPHContext) throws {
        guard let type = GRPHTypes.parse(context: context, literal: groups[3]!.trimmingCharacters(in: .whitespaces)) else {
            throw GRPHCompileError(type: .parse, message: "Unknown type '\(groups[3]!)'")
        }
        guard groups[5] != nil else {
            throw GRPHCompileError(type: .parse, message: "A variable must have a value when it is defined")
        }
        let name = groups[4]!
        guard context.findVariableInScope(named: name) == nil else {
            throw GRPHCompileError(type: .parse, message: "Invalid redeclaration of variable '\(name)'")
        }
        guard GRPHCompiler.varNameRequirement.firstMatch(string: name) != nil else {
            throw GRPHCompileError(type: .parse, message: "Invalid variable name '\(name)'")
        }
        context.addVariable(Variable(name: name, type: type, final: groups[2] != nil, compileTime: true), global: groups[1] != nil)
        self.init(lineNumber: lineNumber, global: groups[1] != nil, constant: groups[2] != nil, type: type, name: groups[4]!, value: try Expressions.parse(context: context, infer: type, literal: groups[5]!))
    }
    
    func run(context: inout GRPHContext) throws {
        let content = try GRPHTypes.autobox(value: try value!.eval(context: context), expected: type)
        let v = Variable(name: name, type: type, content: content, final: constant)
        context.addVariable(v, global: global)
        if context.runtime?.debugging ?? false {
            printout("[DEBUG VAR \(v.name)=\(v.content ?? "<@#no content#>")]")
        }
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)\(global ? "global " : "")\(constant ? "final " : "")\(type.string) \(name)\(value == nil ? "" : " = \(value!.string)")\n"
    }
}
