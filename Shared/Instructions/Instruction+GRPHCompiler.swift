//
//  Instruction+GRPHCompiler.swift
//  Instruction+GRPHCompiler
//
//  Created by Emil Pedersen on 02/09/2021.
//

import Foundation

extension VariableDeclarationInstruction {
    static let pattern = try! NSRegularExpression(pattern: "^(global +)?(final +)?(\(Expressions.typePattern)) +([$A-Za-z_][A-Za-z0-9_]*)(?: *= *(.*))?$")
    
    init(lineNumber: Int, groups: [String?], context: CompilingContext) throws {
        guard groups[5] != nil else {
            throw GRPHCompileError(type: .parse, message: "A variable must have a value when it is defined")
        }
        let name = groups[4]!
        let value: Expression
        let type: GRPHType?
        if groups[3] == "auto" {
            value = try Expressions.parse(context: context, infer: nil, literal: groups[5]!)
            type = nil
        } else if let type0 = GRPHTypes.parse(context: context, literal: groups[3]!.trimmingCharacters(in: .whitespaces)) {
            value = try Expressions.parse(context: context, infer: type0, literal: groups[5]!)
            type = type0
        } else {
            throw GRPHCompileError(type: .parse, message: "Unknown type '\(groups[3]!)'")
        }
        try self.init(lineNumber: lineNumber, context: context, global: groups[1] != nil, constant: groups[2] != nil, typeOrAuto: type, name: name, exp: value)
    }
}

extension AssignmentInstruction {
    static let pattern = try! NSRegularExpression(pattern: "^([^ \\n]+) *(\\+|-|\\*|\\/|%|&|\\||\\^|<<|>>>|>>)?= *(.*)$")
    
    init(lineNumber: Int, context: CompilingContext, groups: [String?]) throws {
        guard let exp = try Expressions.parse(context: context, infer: nil, literal: groups[1]!) as? AssignableExpression else {
            throw GRPHCompileError(type: .parse, message: "The left-hand side of an assignment must be a variable or a field")
        }
        try self.init(lineNumber: lineNumber, context: context, assigned: exp, op: groups[2], value: Expressions.parse(context: context, infer: exp.getType(context: context, infer: SimpleType.mixed), literal: groups[3]!))
    }
}

extension ArrayModificationInstruction {
    static let pattern = try! NSRegularExpression(pattern: "([^ ]+)\\{(.+)\\} *= *(.*)")
    
    init(lineNumber: Int, context: CompilingContext, groups: [String?]) throws {
        var inside = groups[2]!
        var op: ArrayModificationOperation = .set
        if inside.hasSuffix("+") {
            op = .add
            inside.removeLast()
        } else if inside.hasSuffix("-") {
            op = .remove
            inside.removeLast()
        } else if inside.hasSuffix("=") {
            inside.removeLast()
        }
        let index: Expression?
        if inside.isEmpty {
            index = nil
        } else {
            index = try GRPHTypes.autobox(context: context, expression: Expressions.parse(context: context, infer: SimpleType.integer, literal: inside), expected: SimpleType.integer)
        }
        guard let v = context.findVariable(named: groups[1]!) else {
            throw GRPHCompileError(type: .undeclared, message: "Undeclared variable '\(groups[1]!)'")
        }
        guard let arr = v.type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "Expected an array in array modification, got a \(v.type)")
        }
        let value = groups[3]!.trimmingCharacters(in: .whitespaces)
        let exp = value.isEmpty ? nil : try GRPHTypes.autobox(context: context, expression: Expressions.parse(context: context, infer: arr.content, literal: value), expected: arr.content)
        try self.init(lineNumber: lineNumber, name: v.name, op: op, index: index, value: exp)
    }
}
