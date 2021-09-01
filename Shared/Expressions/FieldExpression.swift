//
//  FieldExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct FieldExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.+)\\.([A-Za-z0-9_]+)$")
    
    let on: Expression
    let field: Field
    
    func eval(context: RuntimeContext) throws -> GRPHValue {
        field.getValue(on: try on.eval(context: context))
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        field.type
    }
    
    var string: String {
        "\(on.bracketized).\(field.name)"
    }
    
    var needsBrackets: Bool { false }
}

extension FieldExpression: AssignableExpression {
    func checkCanAssign(context: CompilingContext) throws {
        guard field.writeable else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot assign to final field '\(field.type).\(field.name)'")
        }
    }
    
    func eval(context: RuntimeContext, cache: inout [GRPHValue]) throws -> GRPHValue {
        if let on = on as? AssignableExpression {
            cache.append(try on.eval(context: context, cache: &cache))
        } else {
            cache.append(try on.eval(context: context))
        }
        return field.getValue(on: cache.last!)
    }
    
    func assign(context: RuntimeContext, value: GRPHValue, cache: inout [GRPHValue]) throws {
        var modified = cache.last!
        try field.setValue(on: &modified, value: value)
        // if 'modified' is a reference type, it is already updated
        if type(of: modified) is AnyClass {
            if modified is GShape {
                context.runtime.triggerAutorepaint()
            }
            return
        }
        cache.removeLast()
        if let on = on as? AssignableExpression {
            try on.assign(context: context, value: modified, cache: &cache)
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "Value type couldn't be modified back")
        }
    }
}

struct ConstantPropertyExpression: Expression {
    let property: TypeConstant
    let inType: GRPHType
    
    func eval(context: RuntimeContext) throws -> GRPHValue {
        property.value
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        property.type
    }
    
    var string: String {
        "\(inType.string).\(property.name)"
    }
    
    var needsBrackets: Bool { false }
}

// These could return types directly in a future version

struct ValueTypeExpression: Expression {
    let on: Expression
    
    func eval(context: RuntimeContext) throws -> GRPHValue {
        try GRPHTypes.realType(of: on.eval(context: context), expected: nil).string
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    var string: String {
        "\(on.bracketized).type"
    }
    
    var needsBrackets: Bool { false }
}

struct TypeValueExpression: Expression {
    let type: GRPHType
    
    func eval(context: RuntimeContext) throws -> GRPHValue {
        type.string
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    var string: String {
        "[\(type.string)].TYPE"
    }
    
    var needsBrackets: Bool { false }
}
