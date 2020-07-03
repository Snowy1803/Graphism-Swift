//
//  Property.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

public protocol Property {
    var name: String { get }
    var type: GRPHType { get }
}

public struct TypeConstant: Property {
    public var name: String
    public var type: GRPHType
    public var value: GRPHValue
}

public protocol Field: Property {
    func getValue(on: GRPHValue) -> GRPHValue
    func setValue(on: inout GRPHValue, value: GRPHValue) throws
    
    var writeable: Bool { get }
}

public struct VirtualField<On: GRPHValue>: Field {
    public var name: String
    public var type: GRPHType
    
    var getter: (_ on: On) -> GRPHValue
    var setter: ((_ on: inout On, _ newValue: GRPHValue) throws -> Void)?
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        getter(on as! On)
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) throws {
        guard let setter = setter else {
            // ADD throw
            fatalError("TODO")
        }
        if var copy = on as? On {
            try setter(&copy, value)
            on = copy
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public var writeable: Bool { setter != nil }
}

public struct ErasedField: Field {
    public var name: String
    public var type: GRPHType
    
    var getter: (_ on: GRPHValue) -> GRPHValue
    var setter: ((_ on: inout GRPHValue, _ newValue: GRPHValue) throws -> Void)?
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        getter(on)
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) throws {
        guard let setter = setter else {
            // ADD throw
            fatalError("TODO")
        }
        try setter(&on, value)
    }
    
    public var writeable: Bool { setter != nil }
}

public struct KeyPathField<On: GRPHValue, Value: GRPHValue>: Field {
    public var name: String
    public var type: GRPHType
    
    var keyPath: WritableKeyPath<On, Value>
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        if let on = on as? On {
            return on[keyPath: keyPath]
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) {
        if var copy = on as? On {
            copy[keyPath: keyPath] = value as! Value
            on = copy
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public var writeable: Bool { true }
}
