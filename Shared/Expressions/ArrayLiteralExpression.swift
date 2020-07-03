//
//  ArrayLiteralExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct ArrayLiteralExpression: Expression {
    static let pattern = try! NSRegularExpression(pattern: "^(\(Expressions.typePattern))? *\\{(.*)\\}$")
    
    var wrapped: GRPHType
    var values: [Expression]
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        let array = GRPHArray(of: wrapped)
        for val in values {
            var res = try val.eval(context: context)
            if GRPHTypes.type(of: res, expected: wrapped).isInstance(of: wrapped) {
                // okay
            } else if let int = res as? Int, wrapped as? SimpleType == SimpleType.float { // Backwards compatibility
                res = Float(int)
            } else {
                // TODO throw runtime error : "'" + res + "' (" + Type.getType(res, cmp) + ") is not a valid value in a {" + cmp + "}"
            }
            // ADD array.wrapped.append(GRPHTypes.autobox(res, exprected: wrapped))
        }
        return array
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
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
