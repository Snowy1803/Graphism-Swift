//
//  FunctionDeclarationBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

class FunctionDeclarationBlock: BlockInstruction {
    static let equals = try! NSRegularExpression(pattern: "=")
    static let inlineDeclaration = try! NSRegularExpression(pattern: "\(Expressions.typePattern) [A-Za-z_]+\\[.*\\] = .+")
    
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    var generated: Function!
    var defaults: [Expression?] = []
    var returnDefault: Expression?
    
    init(lineNumber: Int, context: inout GRPHContext, returnType: GRPHType, name: String, def: String) throws {
        self.lineNumber = lineNumber
        let context = createContext(&context)
        // finding returnDefault
        var couple: (String, String)?
        try! FunctionDeclarationBlock.equals.allMatches(in: def) { range in
            let a = def[..<range.lowerBound] // before =
            let b = def[range.upperBound...] // after =
            if Expressions.checkBalance(literal: a) && Expressions.checkBalance(literal: b) {
                couple = (a.trimmingCharacters(in: .whitespaces), b.trimmingCharacters(in: .whitespaces))
            }
        }
        let definition: String
        if let couple = couple {
            definition = couple.0
            let defaultReturn = try Expressions.parse(context: context, infer: returnType, literal: couple.1)
            guard !returnType.isTheVoid else {
                throw GRPHCompileError(type: .parse, message: "Unexpected default value in void function")
            }
            guard try returnType.isInstance(context: context, expression: defaultReturn) else {
                throw GRPHCompileError(type: .parse, message: "Expected a default return value of type \(returnType), found a \(try defaultReturn.getType(context: context, infer: returnType))")
            }
            returnDefault = defaultReturn
        } else {
            definition = def
        }
        guard let openBracket = definition.firstIndex(of: "["),
              definition.last == "]" else {
            throw GRPHCompileError(type: .parse, message: "Invalid function declaration, expected brackets")
        }
        let params = splitParameters(string: definition[definition.index(after: openBracket)..<definition.index(before: definition.endIndex)])
        var varargs = false
        defaults = [Expression?](repeating: nil, count: params.count)
        var i = 0
        let pars = try params.map { param -> Parameter in
            guard let space = param.firstIndex(of: " ") else {
                throw GRPHCompileError(type: .parse, message: "Expected format 'type name' for each parameter")
            }
            guard let ptype = GRPHTypes.parse(context: context, literal: String(param[..<space])) else {
                throw GRPHCompileError(type: .parse, message: "Unknown type '\(param[..<space])'")
            }
            let remainder = param[space...].trimmingCharacters(in: .whitespaces)
            let optional: Bool
            let pname: String
            if let equals = remainder.firstIndex(of: "=") {
                defaults[i] = try Expressions.parse(context: context, infer: ptype, literal: remainder[remainder.index(after: equals)...].trimmingCharacters(in: .whitespaces))
                pname = remainder[..<equals].trimmingCharacters(in: .whitespaces)
                optional = true
                context.variables.append(Variable(name: pname, type: ptype, final: false, compileTime: true))
            } else if remainder.hasSuffix("...") {
                guard i == params.count - 1 else {
                    throw GRPHCompileError(type: .parse, message: "The varargs '...' must be the last parameter")
                }
                pname = remainder.dropLast(3).trimmingCharacters(in: .whitespaces)
                optional = false // varargs needs at least 1 argument
                varargs = true
                context.variables.append(Variable(name: pname, type: ptype.inArray, final: false, compileTime: true))
            } else if remainder.hasSuffix("?") {
                pname = remainder.dropLast().trimmingCharacters(in: .whitespaces)
                optional = true
                context.variables.append(Variable(name: pname, type: ptype.optional, final: false, compileTime: true))
            } else {
                pname = remainder
                optional = false
                context.variables.append(Variable(name: pname, type: ptype, final: false, compileTime: true))
            }
            guard GRPHCompiler.varNameRequirement.firstMatch(string: pname) != nil else {
                throw GRPHCompileError(type: .parse, message: "Illegal var name '\(pname)'")
            }
            i += 1
            return Parameter(name: pname, type: ptype, optional: optional)
        }
        generated = Function(ns: NameSpaces.none, name: name, parameters: pars, returnType: returnType, varargs: varargs, executable: executeFunction(context:params:))
        context.compiler!.imports.append(generated)
    }
    
    convenience init(lineNumber: Int, context: inout GRPHContext, def: String) throws {
        if let bracket = def.firstIndex(of: "["),
           let space = def.firstIndex(of: " "),
           space < bracket {
            let typeLiteral = String(def[..<space])
            let returnType: GRPHType
            if let rtype = GRPHTypes.parse(context: context, literal: typeLiteral) {
                returnType = rtype
            } else {
                throw GRPHCompileError(type: .parse, message: "Unknown return type '\(typeLiteral)'")
            }
            let name = def[space..<bracket].trimmingCharacters(in: .whitespaces)
            guard name.allSatisfy({ $0 == "_" || ($0.isASCII && $0.isLetter) }) else {
                throw GRPHCompileError(type: .parse, message: "Invalid function name '\(name)'")
            }
            try self.init(lineNumber: lineNumber, context: &context, returnType: returnType, name: name, def: def)
            return
        }
        throw GRPHCompileError(type: .parse, message: "Invalid #function declaration")
    }
    
    func createContext(_ context: inout GRPHContext) -> GRPHBlockContext {
        let ctx = GRPHFunctionContext(parent: context, function: self)
        context = ctx
        return ctx
    }
    
    func splitParameters(string: Substring) -> [String] {
        var result = [String]()
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        var last = trimmed.startIndex
        try! Expressions.comma.allMatches(in: trimmed) { range in
            let exp = trimmed[last..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            if Expressions.checkBalance(literal: exp) {
                result.append(exp)
                last = range.upperBound
            }
        }
        let exp = trimmed[last...].trimmingCharacters(in: .whitespaces)
        if Expressions.checkBalance(literal: exp) {
            result.append(exp)
        }
        return result
    }
    
    func executeFunction(context: GRPHContext, params: [GRPHValue?]) throws -> GRPHValue {
        do {
            let ctx = GRPHFunctionContext(parent: context, function: self)
            try parseParameters(context: ctx, params: params)
            try runChildren(context: ctx)
            if let returning = ctx.currentReturnValue {
                return returning
            } else if let returning = returnDefault {
                return try returning.eval(context: ctx)
            } else if generated.returnType.isTheVoid {
                return GRPHVoid.void
            } else {
                throw GRPHRuntimeError(type: .unexpected, message: "No #return value nor default value in non-void function")
            }
        } catch var exception as GRPHRuntimeError {
            exception.stack.append("\tat \(type(of: self)); line \(line)")
            throw exception
        }
    }
    
    func parseParameters(context: GRPHFunctionContext, params: [GRPHValue?]) throws {
        var varargs: GRPHArray? = nil
        for i in 0..<params.count {
            let val = params[i]
            let p = generated.parameter(index: i)
            if generated.varargs && i >= generated.parameters.count - 1 {
                if varargs == nil {
                    varargs = GRPHArray(of: p.type)
                    context.variables.append(Variable(name: p.name, type: p.type.inArray, content: varargs, final: false))
                }
                varargs!.wrapped.append(val!)
            } else if p.optional {
                if let def = defaults[i] {
                    if val == nil {
                        context.variables.append(Variable(name: p.name, type: p.type, content: try def.eval(context: context), final: false))
                    } else {
                        context.variables.append(Variable(name: p.name, type: p.type, content: val, final: false))
                    }
                } else {
                    context.variables.append(Variable(name: p.name, type: p.type.optional, content: GRPHOptional(val), final: false))
                }
            } else {
                context.variables.append(Variable(name: p.name, type: p.type, content: val, final: false))
            }
        }
        // Optional trailing parameters
        if params.count < generated.parameters.count {
            for i in params.count..<generated.parameters.count {
                let p = generated.parameter(index: i)
                if let def = defaults[i] {
                    context.variables.append(Variable(name: p.name, type: p.type, content: try def.eval(context: context), final: false))
                } else {
                    context.variables.append(Variable(name: p.name, type: p.type.optional, content: GRPHOptional.null, final: false))
                }
            }
        }
    }
    
    func canRun(context: GRPHBlockContext) throws -> Bool { false }
    
    var name: String {
        var str = "function \(generated.returnType.string) \(generated.name)["
        var i = 0
        generated.parameters.forEach { p in
            if i > 0 {
                str += ", "
            }
            str += "\(p.type) \(p.name)"
            if p.optional {
                if let value = defaults[i] {
                    str += " = \(value)"
                } else {
                    str += "?"
                }
            }
            i += 1
        }
        if generated.varargs {
            str += "..."
        }
        str += "]"
        if let returnDefault = returnDefault {
            str += " = \(returnDefault)"
        }
        return str
    }
}
