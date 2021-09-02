//
//  RandomNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 12/07/2020.
//

import Foundation

extension RandomNameSpace: ImplementedNameSpace {
    
    func registerImplementations(reg: NativeFunctionRegistry) throws {
        reg.implement(function: exportedFunctions[named: "randomInteger"]) { ctx, params in
            return Int.random(in: 0..<(params[0] as! Int))
        }
        reg.implement(function: exportedFunctions[named: "randomFloat"]) { ctx, params in
            return Float.random(in: 0..<1)
        }
        reg.implement(function: exportedFunctions[named: "randomString"]) { ctx, params in
            let characters = params.count == 1 ? "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" : params[1] as! String
            if characters.isEmpty {
                throw GRPHRuntimeError(type: .invalidArgument, message: "randomString characters cannot be empty, don't pass the characters parameter to use the default value")
            }
            var str = ""
            for _ in 0..<(params[0] as! Int) {
                str.append(characters.randomElement()!)
            }
            return str
        }
        reg.implement(function: exportedFunctions[named: "randomBoolean"]) { ctx, params in
            return Bool.random()
        }
        reg.implement(function: exportedFunctions[named: "shuffleString"]) { ctx, params in
            return String((params[0] as! String).shuffled())
        }
        
        reg.implement(method: exportedMethods[named: "shuffled", inType: SimpleType.string]) { context, on, params in
            return String((on as! String).shuffled())
        }
        
        reg.implement(method: exportedMethods[named: "shuffleArray", inType: SimpleType.mixed.inArray]) { context, on, params in
            let on = on as! GRPHArray
            on.wrapped.shuffle()
            return GRPHVoid.void
        }
        
        // This one is generic, defined in the type
        reg.implement(methodWithSignature: "{T} {T}.random>shuffled[]") { ctx, array, values in
            let array = array as! GRPHArray
            return GRPHArray(array.wrapped.shuffled(), of: array.content)
        }
    }
}
