//
//  StringUtilsNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 12/07/2020.
//

import Foundation

struct StringUtilsNameSpace: NameSpace {
    var name: String { "strutils" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "getStringLength", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.integer) { ctx, params in
                return (params[0] as! String).count
            },
            Function(ns: self, name: "substring", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "start", type: SimpleType.integer), Parameter(name: "end", type: SimpleType.integer, optional: true)], returnType: SimpleType.string) { ctx, params in
                let subject = params[0] as! String
                let start = subject.index(subject.startIndex, offsetBy: params[1] as! Int)
                let end = params.count == 2 ? subject.endIndex : subject.index(subject.startIndex, offsetBy: params[2] as! Int)
                return String(subject[start..<end])
            },
            Function(ns: self, name: "indexInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.integer) { ctx, params in
                let subject = params[0] as! String
                if let index = subject.range(of: params[1] as! String)?.lowerBound {
                    return subject.distance(from: subject.startIndex, to: index)
                }
                return -1
            },
            Function(ns: self, name: "lastIndexInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.integer) { ctx, params in
                let subject = params[0] as! String
                if let index = subject.range(of: params[1] as! String, options: .backwards)?.lowerBound {
                    return subject.distance(from: subject.startIndex, to: index)
                }
                return -1
            },
            Function(ns: self, name: "stringContains", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.boolean) { ctx, params in
                return (params[0] as! String).contains(params[1] as! String)
            },
            Function(ns: self, name: "charToInteger", parameters: [Parameter(name: "char", type: SimpleType.string)], returnType: SimpleType.integer) { ctx, params in
                if let scalar = (params[0] as! String).unicodeScalars.first {
                    return Int(scalar.value)
                }
                throw GRPHRuntimeError(type: .invalidArgument, message: "Given string ins empty")
            },
            Function(ns: self, name: "integerToChar", parameters: [Parameter(name: "codePoint", type: SimpleType.integer)], returnType: SimpleType.string) { ctx, params in
                if let cp = UnicodeScalar(params[0] as! Int) {
                    return String(cp)
                }
                return ""
            },
            Function(ns: self, name: "split", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.string.inArray) { ctx, params in
                return GRPHArray((params[0] as! String).components(separatedBy: params[1] as! String), of: SimpleType.string)
            },
            Function(ns: self, name: "joinStrings", parameters: [Parameter(name: "strings", type: SimpleType.string.inArray), Parameter(name: "delimiter", type: SimpleType.string, optional: true)], returnType: SimpleType.string) { ctx, params in
                return (params[0] as! GRPHArray).wrapped.map { $0 as! String}.joined(separator: params.count == 1 ? "" : params[1] as! String)
            },
            Function(ns: self, name: "setStringLength", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "length", type: SimpleType.integer), Parameter(name: "fill", type: SimpleType.string, optional: true)], returnType: SimpleType.string) { ctx, params in
                let subject = params[0] as! String
                let length = params[1] as! Int
                if subject.count == length {
                    return subject
                } else if subject.count >= length {
                    return String(subject[subject.startIndex..<subject.index(subject.startIndex, offsetBy: length)])
                }
                let fill = params.count == 2 || (params[2] as! String).isEmpty ? " " : params[2] as! String
                let result = subject + String(repeating: fill, count: (length - subject.count - 1) / fill.count + 1)
                return String(result[result.startIndex..<result.index(result.startIndex, offsetBy: length)])
            }
        ]
    }
}
