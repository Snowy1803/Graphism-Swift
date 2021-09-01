//
//  AssignmentInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct AssignmentInstruction: Instruction {
    static let pattern = try! NSRegularExpression(pattern: "^([^ \\n]+) *(\\+|-|\\*|\\/|%|&|\\||\\^|<<|>>>|>>)?= *(.*)$")
    
    let lineNumber: Int
    let assigned: AssignableExpression
    let value: Expression
    let virtualized: Bool
    
    init(lineNumber: Int, context: CompilingContext, assigned: AssignableExpression, op: String?, value: Expression) throws {
        self.lineNumber = lineNumber
        self.assigned = assigned
        
        let varType = try assigned.getType(context: context, infer: SimpleType.mixed)
        let avalue = try GRPHTypes.autobox(context: context, expression: value, expected: varType)
        
        guard try varType.isInstance(context: context, expression: avalue) else {
            throw GRPHCompileError(type: .typeMismatch, message: "Incompatible types '\(try avalue.getType(context: context, infer: SimpleType.mixed))' and '\(varType)' in assignment")
        }
        
        if let op = op {
            self.virtualized = true
            self.value = try BinaryExpression(context: context, left: VirtualExpression(type: assigned.getType(context: context, infer: SimpleType.mixed)), op: op, right: avalue)
        } else {
            self.virtualized = false
            self.value = avalue
        }
        try assigned.checkCanAssign(context: context)
    }
    
    init(lineNumber: Int, context: CompilingContext, groups: [String?]) throws {
        guard let exp = try Expressions.parse(context: context, infer: nil, literal: groups[1]!) as? AssignableExpression else {
            throw GRPHCompileError(type: .parse, message: "The left-hand side of an assignment must be a variable or a field")
        }
        try self.init(lineNumber: lineNumber, context: context, assigned: exp, op: groups[2], value: Expressions.parse(context: context, infer: exp.getType(context: context, infer: SimpleType.mixed), literal: groups[3]!))
    }
    
    func toString(indent: String) -> String {
        var op = ""
        var right = value
        if virtualized, let infix = value as? BinaryExpression {
            op = infix.op.string
            right = infix.right
        }
        return "\(line):\(indent)\(assigned) \(op)= \(right)\n"
    }
    
    struct VirtualExpression: Expression {
        let type: GRPHType
        
        #warning("expr")
        func eval(context: RuntimeContext) throws -> GRPHValue {
            (context as! VirtualAssignmentRuntimeContext).virtualValue
        }
        
        func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
            type
        }
        
        var string: String { "[VIRTUAL::]" } // never called
        
        var needsBrackets: Bool { false } // never called
    }
}

protocol AssignableExpression: Expression {
    func checkCanAssign(context: CompilingContext) throws
}
