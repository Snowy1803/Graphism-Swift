//
//  ForEachBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class ForEachBlock: BlockInstruction {
    var varName: String
    var array: Expression
    var inOut: Bool
    
    init(lineNumber: Int, context: GRPHContext, varName: String, array: Expression) throws {
        self.inOut = varName.hasPrefix("&") // new in Swift Edition
        self.varName = inOut ? String(varName.dropFirst()) : varName
        self.array = array
        super.init(lineNumber: lineNumber)
        
        let type = try array.getType(context: context, infer: ArrayType(content: SimpleType.mixed))
        
        guard let arrtype = type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "#foreach needs an array, a \(type) was given")
        }
        
        guard GRPHCompiler.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    override func run(context: GRPHContext) throws {
        canNextRun = true
        broken = false
        var i = 0
        let arr = try GRPHTypes.autobox(value: array.eval(context: context), expected: ArrayType(content: SimpleType.mixed)) as! GRPHArray
        if mustRun(context: context) {
            throw GRPHRuntimeError(type: .unexpected, message: "Cannot fallthrough a #foreach block")
        }
        while !broken && i < arr.count {
            variables.removeAll()
            let v = Variable(name: varName, type: arr.content, content: arr.wrapped[i], final: !inOut)
            variables.append(v)
            if context.runtime?.debugging ?? false {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
            try runChildren(context: context)
            if inOut {
                arr.wrapped[i] = variables.first(where: { $0.name == varName })!.content!
            }
            i += 1
        }
    }
    
    override var name: String { "foreach \(inOut ? "&" : "")\(varName) : \(array.string)" }
}
