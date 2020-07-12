//
//  MathNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation

struct MathNameSpace: NameSpace {
    var name: String { "math" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "sum", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true) { ctx, params in
                return params.map { $0 as? Float ?? Float($0 as! Int) }.reduce(into: 0 as Float) { $0 += $1 }
            },
            Function(ns: self, name: "difference", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true) { ctx, params in
                let params = params.map { $0 as? Float ?? Float($0 as! Int) }
                return params.dropFirst().reduce(into: params[0]) { $0 -= $1 }
            },
            Function(ns: self, name: "multiply", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true) { ctx, params in
                return params.map { $0 as? Float ?? Float($0 as! Int) }.reduce(into: 1 as Float) { $0 *= $1 }
            },
            Function(ns: self, name: "divide", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true) { ctx, params in
                let params = params.map { $0 as? Float ?? Float($0 as! Int) }
                return params.dropFirst().reduce(into: params[0]) { $0 /= $1 }
            },
            Function(ns: self, name: "modulo", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true) { ctx, params in
                let params = params.map { $0 as? Float ?? Float($0 as! Int) }
                return params.dropFirst().reduce(into: params[0]) { $0 = fmodf($0, $1) }
            },
            Function(ns: self, name: "sqrt", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.float) { ctx, params in
                return sqrt(params[0] as? Float ?? Float(params[0] as! Int))
            },
            Function(ns: self, name: "cbrt", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.float) { ctx, params in
                return cbrt(params[0] as? Float ?? Float(params[0] as! Int))
            },
            Function(ns: self, name: "pow", parameters: [Parameter(name: "number", type: SimpleType.num), Parameter(name: "power", type: SimpleType.num)], returnType: SimpleType.float) { ctx, params in
                return pow(params[0] as? Float ?? Float(params[0] as! Int), params[1] as? Float ?? Float(params[1] as! Int))
            },
            Function(ns: self, name: "PI", parameters: [], returnType: SimpleType.float) { ctx, params in
                return Float.pi
            },
            Function(ns: self, name: "round", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.integer) { ctx, params in
                return Int(round(params[0] as? Float ?? Float(params[0] as! Int)))
            },
            Function(ns: self, name: "floor", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.integer) { ctx, params in
                return Int(floor(params[0] as? Float ?? Float(params[0] as! Int)))
            },
            Function(ns: self, name: "ceil", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.integer) { ctx, params in
                return Int(ceil(params[0] as? Float ?? Float(params[0] as! Int)))
            } // asFloat is a cast, asChar is in strutils --> Removed
        ]
    }
}
