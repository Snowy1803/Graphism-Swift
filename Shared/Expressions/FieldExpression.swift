//
//  FieldExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct FieldExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(.+)\\.([A-Za-z0-9_]+)$")
    
    var on: Expression
    var field: Field
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        field.getValue(on: try on.eval(context: context))
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        field.type
    }
    
    var string: String {
        "\(on.bracketized).\(field.name)"
    }
    
    var needsBrackets: Bool { false }
}

extension FieldExpression: AssignableExpression {
    func checkCanAssign(context: GRPHContext) throws {
        guard field.writeable else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot assign to final field '\(field.type).\(field.name)'")
        }
    }
    
    func eval(context: GRPHContext, cache: inout [GRPHValue]) throws -> GRPHValue {
        if let on = on as? AssignableExpression {
            cache.append(try on.eval(context: context, cache: &cache))
        } else {
            cache.append(try on.eval(context: context))
        }
        return field.getValue(on: cache.last!)
    }
    
    func assign(context: GRPHContext, value: GRPHValue, cache: inout [GRPHValue]) throws {
        var modified = cache.last!
        try field.setValue(on: &modified, value: value)
        // if 'modified' is a reference type, it is already updated
        if type(of: modified) is AnyClass {
            if modified is GShape {
                context.runtime?.triggerAutorepaint()
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
    var property: TypeConstant
    var inType: GRPHType
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        property.value
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        property.type
    }
    
    var string: String {
        "\(inType.string).\(property.name)"
    }
    
    var needsBrackets: Bool { false }
}

// These could return types directly in a future version

struct ValueTypeExpression: Expression {
    var on: Expression
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        try GRPHTypes.realType(of: on.eval(context: context), expected: nil).string
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    var string: String {
        "\(on.bracketized).type"
    }
    
    var needsBrackets: Bool { false }
}

struct TypeValueExpression: Expression {
    var type: GRPHType
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        type.string
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    var string: String {
        "[\(type.string)].TYPE"
    }
    
    var needsBrackets: Bool { false }
}
