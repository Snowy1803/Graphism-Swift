//
//  ReflectNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation

struct ReflectNameSpace: NameSpace {
    var name: String { "reflect" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "callFunction", parameters: [Parameter(name: "funcName", type: SimpleType.string), Parameter(name: "namespace", type: SimpleType.string, optional: true), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true) { context, params in
                guard let ns = params.count == 1 || params[1] == nil || (params.count & 1) == 1 ? NameSpaces.none : NameSpaces.namespace(named: params[1] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Namespace '\(params[1]!)' not found")
                }
                guard let f = Function(imports: context.parser.imports, namespace: ns, name: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Function '\(params[0]!)' not found in namespace '\(ns.name)'")
                }
                if params.count <= 2 {
                    guard f.parameters.allSatisfy({ $0.optional }) else {
                        throw GRPHRuntimeError(type: .reflection, message: "Function '\(f.name)' requires arguments")
                    }
                    return try f.executable(context, [])
                }
                // ["name" "ns" "param1" value1] -- params.count == 4 -- drop 2
                // ["name" "param1" value1] -- 3 -- drop 1
                return try f.executable(context, f.labelled(values: params.dropFirst(2 - (params.count & 1)).map { $0! }))
            },
            Function(ns: self, name: "callMethod", parameters: [Parameter(name: "methodName", type: SimpleType.string), Parameter(name: "namespace", type: SimpleType.string), Parameter(name: "on", type: SimpleType.mixed), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true) { context, params in
                guard let ns = NameSpaces.namespace(named: params[1] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Namespace '\(params[1]!)' not found")
                }
                let value = params[2]!
                let valueType = GRPHTypes.type(of: value)
                guard let f = Method(imports: context.parser.imports, namespace: ns, name: params[0] as! String, inType: valueType) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Function '\(params[0]!)' not found in namespace '\(ns.name)'")
                }
                return try f.executable(context, value, f.labelled(values: params.dropFirst(3).map { $0! }))
            },
            Function(ns: self, name: "callConstructor", parameters: [Parameter(name: "type", type: SimpleType.string), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true) { context, params in
                guard let type = GRPHTypes.parse(context: context, literal: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Type '\(params[0]!)' not found")
                }
                guard let f = type.constructor else {
                    throw GRPHRuntimeError(type: .reflection, message: "Type '\(type.string)' has no constructor")
                }
                return try f.executable(context, f.labelled(values: params.dropFirst(1).map { $0! }))
            },
            Function(ns: self, name: "castTo", parameters: [Parameter(name: "type", type: SimpleType.string), Parameter(name: "param", type: SimpleType.mixed)], returnType: SimpleType.mixed) { context, params in
                guard let type = GRPHTypes.parse(context: context, literal: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Type '\(params[0]!)' not found")
                }
                let ab = try GRPHTypes.autobox(value: params[1]!, expected: type)
                if let value = CastExpression.cast(value: ab, to: type) {
                    return value
                }
                throw GRPHRuntimeError(type: .reflection, message: "Impossible cast from '\(GRPHTypes.type(of: ab).string)' to '\(type.string)'")
            },
            Function(ns: self, name: "getVersion", parameters: [Parameter(name: "of", type: SimpleType.string, optional: true)], returnType: SimpleType.string) { context, params in
                if let v = RequiresInstruction.currentVersion(plugin: params[0] as? String ?? "GRPH") {
                    return v.description
                }
                throw GRPHRuntimeError(type: .reflection, message: "Unknown plugin '\(params[0]!)'")
            },
            Function(ns: self, name: "hasVersion", parameters: [Parameter(name: "of", type: SimpleType.string), Parameter(name: "min", type: SimpleType.string, optional: true)], returnType: SimpleType.boolean) { context, params in
                if let v = RequiresInstruction.currentVersion(plugin: params[0] as! String) {
                    if let q = params[1] as? String,
                       let query = Version(description: q) {
                        return v >= query
                    } else {
                        return true
                    }
                }
                return false
            },
            Function(ns: self, name: "getType", parameters: [Parameter(name: "of", type: SimpleType.mixed)], returnType: SimpleType.string) { context, params in
                GRPHTypes.type(of: params[0]!).string
            },
            Function(ns: self, name: "getDeclaredType", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.string) { context, params in
                guard let v = context.findVariable(named: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in getDeclaredType.")
                }
                return v.type.string
            },
            Function(ns: self, name: "getVarValue", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.mixed) { context, params in
                guard let v = context.findVariable(named: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in getVarValue.")
                }
                return v.content!
            },
            Function(ns: self, name: "isVarFinal", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.boolean) { context, params in
                guard let v = context.findVariable(named: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in isVarFinal.")
                }
                return v.final
            },
            Function(ns: self, name: "isVarDeclared", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.boolean) { context, params in
                return context.findVariable(named: params[0] as! String) != nil
            },
            Function(ns: self, name: "declareVar", parameters: [
                Parameter(name: "name", type: SimpleType.string),
                Parameter(name: "global", type: SimpleType.boolean, optional: true),
                Parameter(name: "type", type: SimpleType.string),
                Parameter(name: "value", type: SimpleType.mixed),
            ]) { context, params in
                let name = params[0] as! String
                let global = params[1] as? Bool ?? false
                guard context.findVariableInScope(named: name) == nil else {
                    throw GRPHRuntimeError(type: .reflection, message: "Invalid redeclaration of variable '\(name)'")
                }
                guard let type = GRPHTypes.parse(context: context, literal: params[2] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Type '\(params[2]!)' not found")
                }
                let value = try GRPHTypes.autobox(value: params[3]!, expected: type)
                let assigned = GRPHTypes.type(of: value, expected: type)
                guard assigned.isInstance(of: type) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Incompatible types, cannot assign a '\(assigned)' to a variable of type '\(type)'")
                }
                context.addVariable(Variable(name: name, type: type, content: value, final: false), global: global)
                return GRPHVoid.void
            },
            Function(ns: self, name: "setVarValue", parameters: [
                Parameter(name: "name", type: SimpleType.string),
                Parameter(name: "value", type: SimpleType.mixed),
            ]) { context, params in
                guard let v = context.findVariable(named: params[0] as! String) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in setVarValue.")
                }
                guard !v.final else {
                    throw GRPHRuntimeError(type: .reflection, message: "Variable is final")
                }
                let value = try GRPHTypes.autobox(value: params[1]!, expected: v.type)
                let assigned = GRPHTypes.type(of: value, expected: v.type)
                guard assigned.isInstance(of: v.type) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Incompatible types, cannot assign a '\(assigned)' to a variable of type '\(v.type)'")
                }
                try v.setContent(value)
                return GRPHVoid.void
            },
        ]
    }
}
