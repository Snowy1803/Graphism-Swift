//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

protocol GRPHType: CustomStringConvertible, Importable {
    var string: String { get }
    
    func isInstance(of other: GRPHType) -> Bool
    
    var staticConstants: [TypeConstant] { get }
    var fields: [Field] { get }
    var constructor: Constructor? { get }
    var includedMethods: [Method] { get }
    
    var supertype: GRPHType { get }
    var final: Bool { get }
}

extension GRPHType {
    var isTheMixed: Bool {
        self as? SimpleType == SimpleType.mixed
    }
    
    var isTheVoid: Bool {
        self as? SimpleType == SimpleType.void
    }
    
    var inArray: ArrayType {
        ArrayType(content: self)
    }
    
    var optional: OptionalType {
        OptionalType(wrapped: self)
    }
    
    func isInstance(context: GRPHContext, expression: Expression) throws -> Bool {
        return GRPHTypes.autoboxed(type: try expression.getType(context: context, infer: self), expected: self).isInstance(of: self)
    }
    
    // default: None
    var staticConstants: [TypeConstant] {[]}
    var fields: [Field] {[]}
    var supertype: GRPHType { SimpleType.mixed }
    var final: Bool { false }
    var constructor: Constructor? { nil }
    var includedMethods: [Method] {[]}
    
    var description: String {
        string
    }
    
    var exportedTypes: [GRPHType] { [self] }
}

func | (lhs: GRPHType, rhs: GRPHType) -> MultiOrType {
    MultiOrType(type1: lhs, type2: rhs)
}

func == (lhs: GRPHType, rhs: GRPHType) -> Bool {
    lhs.string == rhs.string
}

func != (lhs: GRPHType, rhs: GRPHType) -> Bool {
    lhs.string != rhs.string
}

struct GRPHTypes {
    static let funcrefPattern = try! NSRegularExpression(pattern: "funcref<>")
    
    private init() {}
    
    static func parse(context: GRPHContext, literal: String) -> GRPHType? { // needs some GRPHContext
        if literal.isSurrounded(left: "<", right: ">") {
            return parse(context: context, literal: "\(literal.dropLast().dropFirst())")
        }
        if literal.isSurrounded(left: "{", right: "}") {
            return parse(context: context, literal: "\(literal.dropLast().dropFirst())")?.inArray
        }
        if literal.hasSuffix("?") && String(literal.dropLast()).isSurrounded(left: "<", right: ">") {
            return parse(context: context, literal: String(literal.dropLast(2).dropFirst()))?.optional
        }
        if literal.hasPrefix("funcref<") && literal.hasSuffix(">"),
           let generics = parseTopLevelGenerics(in: String(literal.dropFirst(7))),
           generics.count == 2 {
            let returnType = generics[0]
            let params = generics[1]
            if returnType.count == 1,
               let rtype = parse(context: context, literal: returnType[0]) {
                do {
                    let ptypes: [GRPHType] = try params.map {
                        if let type = parse(context: context, literal: $0) {
                            return type
                        } else {
                            throw GRPHCompileError(type: .parse, message: "error does not propagate")
                        }
                    }
                    return FuncRefType(returnType: rtype, parameters: ptypes)
                } catch {
                    return nil
                }
            }
        }
        if literal.contains("|") {
            let components = literal.split(separator: "|", maxSplits: 1)
            if components.count == 2 {
                let left = String(components[0])
                let right = String(components[1])
                if let type1 = parse(context: context, literal: left),
                   let type2 = parse(context: context, literal: right) {
                    return MultiOrType(type1: type1, type2: type2)
                }
            }
        }
        if literal.hasSuffix("?") {
            return parse(context: context, literal: String(literal.dropLast()))?.optional
        }
        if let found = context.parser.imports.flatMap({ $0.exportedTypes }).first(where: { $0.string == literal }) {
            return found
        }
        return context.parser.imports.flatMap({ $0.exportedTypeAliases }).first(where: { $0.name == literal })?.type
    }
    
    /// Type of a value is calculated HERE
    /// It uses GRPHValue.type but takes into account AUTOBOXING and AUTOUNBOXING, based on expected.
    /// Also, type of null is inferred here
    static func type(of value: GRPHValue, expected: GRPHType? = nil) -> GRPHType {
        return autoboxed(type: realType(of: value, expected: expected), expected: expected)
    }
    
    static func autoboxed(type: GRPHType, expected: GRPHType?) -> GRPHType {
        if !(type is OptionalType),
           let expected = expected as? OptionalType { // Boxing
            return OptionalType(wrapped: autoboxed(type: type, expected: expected.wrapped))
        } else if let type = type as? OptionalType,
                  let expected = expected as? OptionalType { // Recursive, multi? optional
            return OptionalType(wrapped: autoboxed(type: type.wrapped, expected: expected.wrapped))
        } else if let type = type as? OptionalType { // Unboxing
            return autoboxed(type: type.wrapped, expected: expected)
        }
        return type
    }
    
    static func autobox(context: GRPHContext, expression: Expression, expected: GRPHType) throws -> Expression {
        let type = try expression.getType(context: context, infer: expected)
        if !(type is OptionalType),
           let expected = expected as? OptionalType { // Boxing
            if context.compiler?.compilerSettings.contains(.strictBoxing) ?? false {
                throw GRPHCompileError(type: .typeMismatch, message: "Strict boxing is enabled. Please box the \(type) into a \(expected) with the '\(expected)' constructor")
            }
            return try ConstructorExpression(ctx: context, boxing: autobox(context: context, expression: expression, expected: expected.wrapped), infer: expected)
        } else if type is OptionalType,
                  let expected = expected as? OptionalType { // Recursive, multi? optional
            if let expression = expression as? ConstructorExpression {
                return try ConstructorExpression(ctx: context, boxing: autobox(context: context, expression: expression.values[0]!, expected: expected.wrapped), infer: expected)
            }
        } else if type is OptionalType { // Unboxing
            if context.compiler?.compilerSettings.contains(.strictUnboxing) ?? false {
                if expected.isTheMixed {
                    return expression // valid
                }
                throw GRPHCompileError(type: .typeMismatch, message: "Strict unboxing is enabled. Please unbox the \(type) into a \(expected) using the postfix unary '!' operator")
            }
            return try autobox(context: context, expression: UnboxExpression(exp: expression), expected: expected)
        }
        return expression
    }
    
    static func autobox(value: GRPHValue, expected: GRPHType) throws -> GRPHValue {
        if let value = value as? GRPHOptional {
            if let expected = expected as? OptionalType { // recursive
                switch value {
                case .null:
                    return value
                case .some(let wrapped):
                    return GRPHOptional.some(try autobox(value: wrapped, expected: expected.wrapped))
                }
            } else { // Unboxing
                switch value {
                case .null:
                    throw GRPHRuntimeError(type: .cast, message: "Tried to auto-unbox a 'null' value")
                case .some(let wrapped):
                    return try autobox(value: wrapped, expected: expected) // Unboxing
                }
            }
        } else if let expected = expected as? OptionalType { // Boxing
            return GRPHOptional.some(try autobox(value: value, expected: expected.wrapped))
        } else {
            return value
        }
    }
    
    /// Use this instead of autobox if you always expect an unwrapped value, as it's faster
    static func unbox(value: GRPHValue) throws -> GRPHValue {
        if let value = value as? GRPHOptional {
            switch value {
            case .null:
                throw GRPHRuntimeError(type: .typeMismatch, message: "Tried to auto-unbox a 'null' value")
            case .some(let wrapped):
                return try unbox(value: wrapped) // Unboxing
            }
        } else {
            return value
        }
    }
    
    static func realType(of value: GRPHValue, expected: GRPHType?) -> GRPHType {
        if let value = value as? GRPHOptional,
           value.isEmpty,
           expected is OptionalType {
            return expected ?? OptionalType(wrapped: SimpleType.mixed)
        }
        return value.type
    }
    
    static func field(named name: String, in type: GRPHType) -> Field? {
        if let property = type.fields.first(where: { $0.name == name }) {
            return property
        }
        if type.isTheMixed {
            return nil
        }
        return field(named: name, in: type.supertype)
    }
}

extension String {
    func isSurrounded(left: Character, right: Character) -> Bool {
        if last == right && first == left {
            let inner = dropLast().dropFirst()
            var deepness = 0
            for char in inner {
                if char == left {
                    deepness += 1
                } else if char == right {
                    deepness -= 1
                    if deepness < 0 {
                        return false
                    }
                }
            }
            if deepness == 0 {
                return true
            }
        }
        return false
    }
}

extension GRPHTypes {
    
    /// Parses generics in the format `<a11+a12><a21+a22>`
    /// The input string must start and end with `<` and `>` respectively.
    static func parseTopLevelGenerics(in str: String) -> [[String]]? {
        var generics: [[String]] = []
        var chevrons = 0
        var last: String.Index?
        for (i, c) in zip(str.indices, str) {
            if c == "<" {
                if chevrons == 0 {
                    if let lastEnd = last {
                        generics.append(splitGeneric(in: String(str[lastEnd..<i].dropFirst().dropLast())))
                    }
                    last = i
                }
                chevrons += 1
            } else if c == ">" {
                chevrons -= 1
                if chevrons < 0 {
                    return nil
                }
            }
        }
        if let lastEnd = last {
            generics.append(splitGeneric(in: String(str[lastEnd...].dropFirst().dropLast())))
        }
        guard chevrons == 0 else {
            return nil
        }
        return generics
    }
    
    static func splitGeneric(in string: String, delimiter: NSRegularExpression = Expressions.plus) -> [String] {
        var result: [String] = []
        var last = string.startIndex
        delimiter.allMatches(in: string) { range in
            let exp = string[last..<range.lowerBound]
            if checkBalanceGeneric(literal: exp) {
                result.append(String(exp))
                last = range.upperBound
            }
        }
        let exp = string[last...]
        if checkBalanceGeneric(literal: exp) {
            result.append(String(exp))
        }
        return result
    }
    
    static func checkBalanceGeneric<S: StringProtocol>(literal str: S) -> Bool {
        if str.isEmpty {
            return false // Empty, most probably an error
        }
        var chevrons = 0
        for c in str {
            if c == "<" {
                chevrons += 1
            } else if c == ">" {
                chevrons -= 1
                if chevrons < 0 {
                    return false
                }
            }
        }
        return chevrons == 0
    }
}
