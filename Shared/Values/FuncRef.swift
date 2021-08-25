//
//  FuncRef.swift
//  FuncRef
//
//  Created by Emil Pedersen on 25/08/2021.
//

import Foundation

struct FuncRef: GRPHValue, Parametrable {
    
    
    var currentType: FuncRefType
    var storage: Storage
    
    var funcName: String {
        switch storage {
        case .function(let function):
            return "function \(function.name)"
        case .method(let method):
            return "method \(method.name)"
        case .constant(_):
            return "constant expression"
        }
    }
    
    var parameters: [Parameter] {
        currentType.parameters.enumerated().map { index, type in
            Parameter(name: "$\(index)", type: type)
        }
    }
    
    var returnType: GRPHType {
        currentType.returnType
    }
    
    var varargs: Bool { false }
    
    var type: GRPHType { currentType }
    
    func isEqual(to other: GRPHValue) -> Bool {
        false // not even equal to itself, it makes no sense to compare function references
    }
}

extension FuncRef {
    enum Storage {
        case function(Function)
        case method(Method)
//        case lambda(Lambda)
        case constant(GRPHValue)
    }
}
