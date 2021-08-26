//
//  FuncRef.swift
//  FuncRef
//
//  Created by Emil Pedersen on 25/08/2021.
//

import Foundation

struct FuncRef: GRPHValue {
    
    var currentType: FuncRefType
    var storage: Storage
    
    var funcName: String {
        switch storage {
        case .function(let function, _):
            return "function \(function.fullyQualifiedName)"
        case .constant(_):
            return "constant expression"
        }
    }
    
    var type: GRPHType { currentType }
    
    func isEqual(to other: GRPHValue) -> Bool {
        false // not even equal to itself, it makes no sense to compare function references
    }
    
    func execute(context: GRPHContext, params: [GRPHValue?]) throws -> GRPHValue {
        switch storage {
        case .function(let function, let argumentGrid):
            var i = 0
            let parmap: [GRPHValue?] = argumentGrid.map {
                if $0 {
                    defer {
                        i += 1
                    }
                    return params[i]
                } else {
                    return nil
                }
            }
            return try function.executable(context, parmap)
        case .constant(let const):
            return const
        }
    }
    
}

extension FuncRef {
    enum Storage {
        case function(Function, argumentGrid: [Bool])
//        case lambda(Lambda)
        case constant(GRPHValue)
    }
}
