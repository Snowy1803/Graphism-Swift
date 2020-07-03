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
    func setValue(on: inout GRPHValue, value: GRPHValue)
}

public struct VirtualField: Field {
    public var name: String
    public var type: GRPHType
    
    var getter: (_ on: GRPHValue) -> GRPHValue
    var setter: (_ on: inout GRPHValue, _ newValue: GRPHValue) -> Void
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        getter(on)
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) {
        setter(&on, value)
    }
}

public struct KeyPathField<On: GRPHValue>: Field {
    public var name: String
    public var type: GRPHType
    
    var keyPath: WritableKeyPath<On, GRPHValue>
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        if let on = on as? On {
            return on[keyPath: keyPath]
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) {
        if var copy = on as? On {
            copy[keyPath: keyPath] = value
            on = copy
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
}
