//
//  ArrayModificationInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 07/07/2020.
//

import Foundation

struct ArrayModificationInstruction: Instruction {
    static let pattern = try! NSRegularExpression(pattern: "([^ ]+)\\{(.+)\\} *= *(.*)")
    let lineNumber: Int
    let name: String
    let op: ArrayModificationOperation
    let index: Expression?
    let value: Expression?
    
    init(lineNumber: Int, name: String, op: ArrayModificationOperation, index: Expression?, value: Expression?) throws {
        self.lineNumber = lineNumber
        self.name = name
        self.op = op
        self.value = value
        self.index = index
        
        if op == .set && index == nil {
            throw GRPHCompileError(type: .invalidArguments, message: "Index or operation required in array modification instruction")
        }
        if op != .remove && value == nil {
            throw GRPHCompileError(type: .invalidArguments, message: "Value required in array modification instruction")
        }
        if op == .remove && index == nil && value == nil {
            throw GRPHCompileError(type: .invalidArguments, message: "Value or index required in array modification instruction")
        }
    }
    
    init(lineNumber: Int, context: GRPHContext, groups: [String?]) throws {
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
            guard try SimpleType.integer.isInstance(context: context, expression: index!) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Expected integer in array modification index")
            }
        }
        guard let v = context.findVariable(named: groups[1]!) else {
            throw GRPHCompileError(type: .undeclared, message: "Undeclared variable '\(groups[1]!)'")
        }
        guard let arr = v.type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "Expected an array in array modification, got a \(v.type)")
        }
        let value = groups[3]!.trimmingCharacters(in: .whitespaces)
        let exp = value.isEmpty ? nil : try GRPHTypes.autobox(context: context, expression: Expressions.parse(context: context, infer: arr.content, literal: value), expected: arr.content)
        if let exp = exp {
            guard try arr.content.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Expected \(arr.content) as array content, got \(try exp.getType(context: context, infer: arr.content))")
            }
        }
        try self.init(lineNumber: lineNumber, name: v.name, op: op, index: index, value: exp)
    }
    
    func run(context: inout GRPHContext) throws {
        guard let v = context.findVariable(named: name) else {
            throw GRPHRuntimeError(type: .unexpected, message: "Undeclared variable '\(name)'")
        }
        let val = try value?.eval(context: context)
        guard let arr = v.content! as? GRPHArray else { // No autoboxing here (consistency with Java version)
            throw GRPHRuntimeError(type: .typeMismatch, message: "Expected an array in array modification, got a \(GRPHTypes.realType(of: v.content!, expected: nil))")
        }
        switch op {
        case .set:
            guard let index = try index?.eval(context: context) as? Int,
                  index < arr.count else {
                throw GRPHRuntimeError(type: .unexpected, message: "Invalid index")
            }
            arr.wrapped[index] = val!
        case .add:
            if let index = try index?.eval(context: context) as? Int {
                guard index <= arr.count else {
                    throw GRPHRuntimeError(type: .unexpected, message: "Invalid index \(index) in insertion for array of length \(arr.count)")
                }
                arr.wrapped.insert(val!, at: index)
            } else {
                arr.wrapped.append(val!)
            }
        case .remove:
            if let index = try index?.eval(context: context) as? Int {
                guard index < arr.count else {
                    throw GRPHRuntimeError(type: .unexpected, message: "Invalid index \(index) in insertion for array of length \(arr.count)")
                }
                if let val = val {
                    if arr.wrapped[index].isEqual(to: val) {
                        arr.wrapped.remove(at: index)
                    }
                } else {
                    arr.wrapped.remove(at: index)
                }
            } else if let val = val,
                      let index = arr.wrapped.firstIndex(where: { $0.isEqual(to: val) }) {
                arr.wrapped.remove(at: index)
            }
        }
        if context.runtime?.debugging ?? false {
            printout("[DEBUG VAR \(v.name)=\(v.content!)]")
        }
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)\(name){\(index?.string ?? "")\(op.rawValue)} = \(value?.string ?? "")\n"
    }
}

enum ArrayModificationOperation: String {
    case set = ""
    case add = "+"
    case remove = "-"
}
