//
//  ConstantExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct ConstantExpression: Expression {
    static let posPattern = try! NSRegularExpression(pattern: "^(-?[0-9.]+),(-?[0-9.]+)$")
    
    var value: StatefulValue
    
    init(boolean: Bool) {
        self.value = boolean
    }
    
    init(stroke: Stroke) {
        self.value = stroke
    }
    
    init(direction: Direction) {
        self.value = direction
    }
    
    init(pos: Pos) {
        self.value = pos
    }
    
    func getType(context: GRPHContext, infer: GRPHType) throws -> GRPHType {
        value.type // The value is always known at compile time, so this is fine
    }
    
    func eval(context: GRPHContext) throws -> GRPHValue {
        value
    }
    
    var string: String { value.state }
    
    var needsBrackets: Bool { false }
}
