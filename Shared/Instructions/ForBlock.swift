//
//  ForBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

class ForBlock: BlockInstruction {
    static let varNameRequirement = try! NSRegularExpression(pattern: "^[$A-Za-z_][A-Za-z0-9_]*$")
    
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
        
        guard ForBlock.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    override func run(context: GRPHContext) throws {
        canNextRun = true
        broken = false
        var i = 0
        let arr = try GRPHTypes.autobox(value: array.eval(context: context), expected: ArrayType(content: SimpleType.mixed)) as! GRPHArray
        while !broken && i < arr.count {
            variables.removeAll()
            let v = Variable(name: varName, type: arr.content, content: arr.wrapped[i], final: !inOut)
            variables.append(v)
            if context.runtime?.debugging ?? false {
                print("[DEBUG VAR \(v.name)=\(v.content!)]")
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
