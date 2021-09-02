//
//  NativeFunctionRegistry.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/09/2021
//

import Foundation

class NativeFunctionRegistry {
    static let shared = NativeFunctionRegistry()
    
    var registered = false
    
    /// Note: We could use an actor, but this is only a workaround: Normally, everything should be added on the same thread, before anything is run.
    let queue = DispatchQueue(label: "NativeFunctionRegistry")
    
    private var constructors: [String: (RuntimeContext, [GRPHValue?]) -> GRPHValue] = [:]
    private var functions: [String: (RuntimeContext, [GRPHValue?]) throws -> GRPHValue] = [:]
    private var methods: [String: (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue] = [:]
    
    func ensureRegistered() {
        if !registered {
            registered = true
            do {
                try NameSpaces.registerAllImplementations()
            } catch {
                printerr("Registering native implementations failed")
                printerr("\(error)")
            }
        }
    }
    
    func implementation(for function: Function) throws -> ((RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
        ensureRegistered()
        guard let imp = functions[function.signature] else {
            throw GRPHRuntimeError(type: .unexpected, message: "No implementation found for native function '\(function.signature)'")
        }
        return imp
    }
    
    func implement(function: Function, with imp: @escaping (RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
        implement(functionWithSignature: function.signature, with: imp)
    }
    
    func implement(functionWithSignature signature: String, with imp: @escaping (RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
//        assert(functions[signature] == nil, "replacing native implementation for the already defined function '\(signature)'")
        queue.sync {
            functions[signature] = imp
        }
    }
    
    func implementation(for method: Method) throws -> ((RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        ensureRegistered()
        guard let imp = methods[method.signature] else {
            throw GRPHRuntimeError(type: .unexpected, message: "No implementation found for native method '\(method.signature)'")
        }
        return imp
    }
    
    func implementation(forMethodWithGenericSignature signature: String) throws -> ((RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        ensureRegistered()
        guard let imp = methods[signature] else {
            throw GRPHRuntimeError(type: .unexpected, message: "No implementation found for native generic method '\(signature)'")
        }
        return imp
    }
    
    func implement(method: Method, with imp: @escaping (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        implement(methodWithSignature: method.signature, with: imp)
    }
    
    func implement(methodWithSignature signature: String, with imp: @escaping (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
//        assert(methods[signature] == nil, "replacing native implementation for the already defined method '\(signature)'")
        queue.sync {
            methods[signature] = imp
        }
    }
    
    func implementation(for constructor: Constructor) -> ((RuntimeContext, [GRPHValue?]) -> GRPHValue) {
        ensureRegistered()
        guard let imp = constructors[constructor.name] else {
            fatalError("No implementation found for constructor '\(constructor.name)'")
        }
        return imp
    }
    
    func implement(constructor: Constructor, with imp: @escaping (RuntimeContext, [GRPHValue?]) -> GRPHValue) {
//        assert(constructors[constructor.name] == nil, "replacing native implementation for the already defined constructor '\(constructor.name)'")
        queue.sync {
            constructors[constructor.name] = imp
        }
    }
}
