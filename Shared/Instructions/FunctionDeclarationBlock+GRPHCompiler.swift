//
//  FunctionDeclarationBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

extension FunctionDeclarationBlock {
    static let equals = try! NSRegularExpression(pattern: "=")
    static let inlineDeclaration = try! NSRegularExpression(pattern: "\(Expressions.typePattern) [A-Za-z_]+\\[.*\\] = .+")
    
    convenience init(lineNumber: Int, context: inout CompilingContext, returnType autoableReturnType: GRPHType?, name: String, def: String) throws {
        self.init(lineNumber: lineNumber)
        let context = createContext(&context)
        // finding returnDefault
        var couple: (String, String)?
        FunctionDeclarationBlock.equals.allMatches(in: def) { range in
            let a = def[..<range.lowerBound] // before =
            let b = def[range.upperBound...] // after =
            if Expressions.checkBalance(literal: a) && Expressions.checkBalance(literal: b) {
                couple = (a.trimmingCharacters(in: .whitespaces), b.trimmingCharacters(in: .whitespaces))
            }
        }
        let definition: String
        let defaultReturnDef: String?
        if let couple = couple {
            definition = couple.0
            defaultReturnDef = couple.1
        } else {
            definition = def
            defaultReturnDef = nil
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
            let mptype: GRPHType?
            if param[..<space] == "auto" {
                mptype = nil
            } else if let ptype = GRPHTypes.parse(context: context, literal: String(param[..<space])) {
                mptype = ptype
            } else {
                throw GRPHCompileError(type: .parse, message: "Unknown type '\(param[..<space])'")
            }
            let remainder = param[space...].trimmingCharacters(in: .whitespaces)
            let optional: Bool
            let pname: String
            let ptype: GRPHType
            if let equals = remainder.firstIndex(of: "=") {
                defaults[i] = try Expressions.parse(context: context, infer: mptype, literal: remainder[remainder.index(after: equals)...].trimmingCharacters(in: .whitespaces))
                pname = remainder[..<equals].trimmingCharacters(in: .whitespaces)
                optional = true
                if let mptype = mptype {
                    ptype = mptype
                } else {
                    ptype = try defaults[i]!.getType(context: context, infer: SimpleType.mixed)
                }
                context.variables.append(Variable(name: pname, type: ptype, final: false, compileTime: true))
            } else if remainder.hasSuffix("...") {
                guard i == params.count - 1 else {
                    throw GRPHCompileError(type: .parse, message: "The varargs '...' must be the last parameter")
                }
                pname = remainder.dropLast(3).trimmingCharacters(in: .whitespaces)
                optional = false // varargs needs at least 1 argument
                varargs = true
                if let mptype = mptype {
                    ptype = mptype
                } else {
                    throw GRPHCompileError(type: .typeMismatch, message: "Cannot infer parameter type without a default value")
                }
                context.variables.append(Variable(name: pname, type: ptype.inArray, final: false, compileTime: true))
            } else if remainder.hasSuffix("?") {
                pname = remainder.dropLast().trimmingCharacters(in: .whitespaces)
                optional = true
                if let mptype = mptype {
                    ptype = mptype
                } else {
                    throw GRPHCompileError(type: .typeMismatch, message: "Cannot infer parameter type without a default value")
                }
                context.variables.append(Variable(name: pname, type: ptype.optional, final: false, compileTime: true))
            } else {
                pname = remainder
                optional = false
                if let mptype = mptype {
                    ptype = mptype
                } else {
                    throw GRPHCompileError(type: .typeMismatch, message: "Cannot infer parameter type without a default value")
                }
                context.variables.append(Variable(name: pname, type: ptype, final: false, compileTime: true))
            }
            guard GRPHCompiler.varNameRequirement.firstMatch(string: pname) != nil else {
                throw GRPHCompileError(type: .parse, message: "Illegal var name '\(pname)'")
            }
            i += 1
            return Parameter(name: pname, type: ptype, optional: optional)
        }
        
        let returnType: GRPHType
        if let defaultReturnDef = defaultReturnDef {
            let defaultReturn = try Expressions.parse(context: context, infer: autoableReturnType, literal: defaultReturnDef)
            if let autoableReturnType = autoableReturnType {
                returnType = autoableReturnType
            } else {
                returnType = try defaultReturn.getType(context: context, infer: SimpleType.mixed)
            }
            guard !returnType.isTheVoid else {
                throw GRPHCompileError(type: .parse, message: "Unexpected default value in void function")
            }
            guard try returnType.isInstance(context: context, expression: defaultReturn) else {
                throw GRPHCompileError(type: .parse, message: "Expected a default return value of type \(returnType), found a \(try defaultReturn.getType(context: context, infer: returnType))")
            }
            returnDefault = defaultReturn
        } else {
            if let autoableReturnType = autoableReturnType {
                returnType = autoableReturnType
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Cannot infer function type without a default value")
            }
        }
        
        generated = Function(ns: NameSpaces.none, name: name, parameters: pars, returnType: returnType, varargs: varargs, storage: .block(self))
        context.imports.append(generated)
    }
    
    convenience init(lineNumber: Int, context: inout CompilingContext, def: String) throws {
        if let bracket = def.firstIndex(of: "["),
           let space = def.firstIndex(of: " "),
           space < bracket {
            let typeLiteral = String(def[..<space])
            let returnType: GRPHType?
            if typeLiteral == "auto" {
                returnType = nil
            } else if let rtype = GRPHTypes.parse(context: context, literal: typeLiteral) {
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
    
    func splitParameters(string: Substring) -> [String] {
        var result = [String]()
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        var last = trimmed.startIndex
        Expressions.comma.allMatches(in: trimmed) { range in
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
}
