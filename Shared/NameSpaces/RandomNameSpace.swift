//
//  RandomNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 12/07/2020.
//

import Foundation

struct RandomNameSpace: NameSpace {
    var name: String { "random" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "randomInteger", parameters: [Parameter(name: "max", type: SimpleType.integer)], returnType: SimpleType.integer) { ctx, params in
                return Int.random(in: 0..<(params[0] as! Int))
            },
            Function(ns: self, name: "randomFloat", parameters: [], returnType: SimpleType.float) { ctx, params in
                return Float.random(in: 0..<1)
            },
            Function(ns: self, name: "randomString", parameters: [Parameter(name: "length", type: SimpleType.integer)], returnType: SimpleType.string) { ctx, params in
                var str = ""
                for _ in 0..<(params[0] as! Int) {
                    let b = Int.random(in: 0..<62)
                    if b < 10 {
                        str.append(Character(UnicodeScalar(b + 48)!))
                    } else if b < 36 {
                        str.append(Character(UnicodeScalar(b + 55)!))
                    } else {
                        str.append(Character(UnicodeScalar(b + 61)!))
                    }
                }
                return str
            },
            Function(ns: self, name: "randomBoolean", parameters: [], returnType: SimpleType.boolean) { ctx, params in
                return Bool.random()
            },
            Function(ns: self, name: "shuffleString", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.string) { ctx, params in
                return String((params[0] as! String).shuffled())
            }
        ]
    }
    
    var exportedMethods: [Method] {
        [
            Method(ns: self, name: "shuffled", inType: SimpleType.string, parameters: [], returnType: SimpleType.string) { context, on, params in
                return String((on as! String).shuffled())
            },
            Method(ns: self, name: "shuffleArray", inType: SimpleType.mixed.inArray, parameters: []) { context, on, params in
                let on = on as! GRPHArray
                on.wrapped.shuffle()
                return GRPHVoid.void
            }
        ]
    }
}
