//
//  InputOutputNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 12/07/2020.
//

import Foundation

struct InputOutputNameSpace: NameSpace {
    var name: String { "stdio" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "getLineInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "line", type: SimpleType.integer)], returnType: SimpleType.string) { ctx, params in
                let line = params[1] as! Int
                return String((params[0] as! String).split(separator: "\n", maxSplits: line + 1)[line])
            },
            Function(ns: self, name: "getLinesInString", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.string.inArray) { ctx, params in
                return GRPHArray((params[0] as! String).components(separatedBy: "\n"), of: SimpleType.string)
            },
            Function(ns: self, name: "getMousePos", parameters: [], returnType: SimpleType.pos.optional) { ctx, params in
                // TODO
                return GRPHOptional.null
            },
            Function(ns: self, name: "getTimeInMillisSinceLoad", parameters: [], returnType: SimpleType.integer) { ctx, params in
                return Int(Date().timeIntervalSince(ctx.runtime.timestamp) * 1000)
            },
            Function(ns: self, name: "getSVGFromCurrentImage", parameters: [], returnType: SimpleType.string) { ctx, params in
                var svg: String = ""
                ctx.runtime.image.toSVG(context: SVGExportContext(), into: &svg)
                return svg
            }
        ]
    }
    
    static var isHeadless: Bool {
        #if GRAPHICAL
        return false // Graphical
        #else
        return true // CLI --> headless
        #endif
    }
}
