//
//  ArrayLiteralExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct ArrayLiteralExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(\(Expressions.typePattern))? *\\{(.*)\\}$")
    
    let wrapped: GRPHType
    let values: [Expression]
    
    func eval(context: RuntimeContext) throws -> GRPHValue {
        let array = GRPHArray(of: wrapped)
        for val in values {
            var res = try val.eval(context: context)
            if GRPHTypes.type(of: res, expected: wrapped).isInstance(of: wrapped) {
                // okay
            } else if let int = res as? Int, wrapped as? SimpleType == SimpleType.float { // Backwards compatibility
                res = Float(int)
            } else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "'\(res)' (\(GRPHTypes.type(of: res, expected: wrapped))) is not a valid value in a {\(wrapped)}")
            }
            array.wrapped.append(res)
        }
        return array
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        ArrayType(content: wrapped)
    }
    
    var string: String {
        var str = "<\(wrapped.string)>{"
        if values.isEmpty {
            return "\(str)}"
        }
        for exp in values {
            if let pos = exp as? ConstantExpression,
               pos.value is Pos {
                str += "[\(exp.string)], " // only location where Pos expressions are bracketized
            } else {
                str += "\(exp.bracketized), "
            }
        }
        return "\(str.dropLast(2))}"
    }
    
    var needsBrackets: Bool { false }
}
