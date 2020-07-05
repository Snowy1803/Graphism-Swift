//
//  AssignmentInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

class AssignmentInstruction: Instruction {
    static let pattern = try! NSRegularExpression(pattern: "^([^ \\n]+) *(\\+|-|\\*|\\/|%|&|\\||\\^|<<|>>>|>>)?= *(.*)$")
    
    var lineNumber: Int
    var assigned: AssignableExpression
    var value: Expression
    
    private var virtualValue: GRPHValue?
    
    init(lineNumber: Int, context: GRPHContext, assigned: AssignableExpression, op: String?, value: Expression) throws {
        self.lineNumber = lineNumber
        self.assigned = assigned
        self.value = value
        if let op = op {
            self.value = try BinaryExpression(context: context, left: VirtualExpression(parent: self), op: op, right: value)
        }
        try assigned.checkCanAssign(context: context)
    }
    
    convenience init(lineNumber: Int, context: GRPHContext, groups: [String?]) throws {
        guard let exp = try Expressions.parse(context: context, infer: nil, literal: groups[1]!) as? AssignableExpression else {
            throw GRPHCompileError(type: .parse, message: "The left-hand side of an assignment must be a variable or a field")
        }
        try self.init(lineNumber: lineNumber, context: context, assigned: exp, op: groups[2], value: Expressions.parse(context: context, infer: exp.getType(context: context, infer: SimpleType.mixed), literal: groups[3]!))
    }
    
    func run(context: GRPHContext) throws {
        try assigned.checkCanAssign(context: context)
        var cache = [GRPHValue]()
        virtualValue = try assigned.eval(context: context, cache: &cache)
        let varType = try assigned.getType(context: context, infer: SimpleType.mixed)
        let val = try GRPHTypes.autobox(value: value.eval(context: context), expected: varType)
        guard GRPHTypes.type(of: val, expected: varType).isInstance(of: varType) else {
            throw GRPHRuntimeError(type: .typeMismatch, message: "Incompatible types '\(GRPHTypes.type(of: val, expected: varType))' and '\(varType)' in assignment")
        }
        try assigned.assign(context: context, value: val, cache: &cache)
    }
    
    func toString(indent: String) -> String {
        var op = ""
        var right = value
        if let infix = value as? BinaryExpression,
           infix.left is VirtualExpression {
            op = infix.op.string
            right = infix.right
        }
        return "\(line):\(indent)\(assigned) \(op)= \(right)\n"
    }
    
    private struct VirtualExpression: Expression {
        unowned var parent: AssignmentInstruction
        
        func eval(context: GRPHContext) throws -> GRPHValue {
            parent.virtualValue!
        }
        
        func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
            try parent.assigned.getType(context: context, infer: infer)
        }
        
        var string: String { "[VIRTUAL::]" } // never called
        
        var needsBrackets: Bool { false } // never called
    }
}

protocol AssignableExpression: Expression {
    func checkCanAssign(context: GRPHContext) throws
    func eval(context: GRPHContext, cache: inout [GRPHValue]) throws -> GRPHValue
    func assign(context: GRPHContext, value: GRPHValue, cache: inout [GRPHValue]) throws
}
