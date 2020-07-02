//
//  GRPHValue.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

/* Immutable types should be structs, mutable types should be classes */
public protocol GRPHValue {
    var type: GRPHType { get }
}

public protocol StatefulValue: GRPHValue {
    var state: String { get }
}

extension Int: StatefulValue {
    
    public init?(byCasting value: GRPHValue) {
        if let int = value as? Int {
            self.init(int)
        } else if let num = value as? Float {
            self.init(num)
        } else if let rot = value as? Rotation {
            self.init(rot.value)
        } else if let str = value as? String {
            self.init(str) // May return nil
        } else {
            return nil
        }
    }
    
    public var type: GRPHType { SimpleType.integer }
    public var state: String { String(self) }
}

extension String: StatefulValue {
    
    public init?(byCasting value: GRPHValue) {
        if let str = value as? String {
            self.init(str) // Not a literal
        } else if let val = value as? StatefulValue {
            self.init(val.state)
        } else {
            return nil
        }
    }
    
    public var type: GRPHType { SimpleType.string }
    public var state: String { self.asLiteral }
}

extension Float: StatefulValue {
    
    public init?(byCasting value: GRPHValue) {
        if let int = value as? Int {
            self.init(int)
        } else if let num = value as? Float {
            self.init(num)
        } else if let rot = value as? Rotation {
            self.init(rot.value)
        } else if let str = value as? String {
            self.init(str) // May return nil
        } else {
            return nil
        }
    }
    
    public var type: GRPHType { SimpleType.float }
    public var state: String { "\(self)F" }
}

extension Bool: StatefulValue {
    
    public init?(byCasting value: GRPHValue) {
        if let bool = value as? Bool {
            self.init(bool)
        } else if let int = value as? Int {
            self.init(int != 0)
        } else if let num = value as? Float {
            self.init(num != 0)
        } else if let rot = value as? Rotation {
            self.init(rot.value != 0)
        } else if let str = value as? String {
            self.init(!str.isEmpty)
        } else if let pos = value as? Pos {
            self.init(pos.x != 0 || pos.y != 0)
        } else if let arr = value as? GRPHArrayProtocol {
            self.init(arr.count != 0)
        } else if let opt = value as? GRPHOptional {
            self.init(!opt.isEmpty)
        } else {
            self.init(true)
        }
    }
    
    public var type: GRPHType { SimpleType.boolean }
    public var state: String { self ? "true" : "false" }
}
