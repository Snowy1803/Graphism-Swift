//
//  GRPHValue.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

/* Immutable types should be structs, mutable types should be classes */
protocol GRPHValue {
    var type: GRPHType { get }
    func isEqual(to other: GRPHValue) -> Bool
}

protocol StatefulValue: GRPHValue {
    var state: String { get }
}

protocol GRPHNumber: GRPHValue {
    init(grph: GRPHNumber)
}

extension GRPHValue where Self: Equatable {
    /// Note that this default implementation doesn't work with multi-inheritence (subclasses) !!!
    func isEqual(to other: GRPHValue) -> Bool {
        if let value = other as? Self {
            return value == self
        }
        return false
    }
}

extension Int: StatefulValue, GRPHNumber {
    
    init?(byCasting value: GRPHValue) {
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
    
    init(grph: GRPHNumber) {
        if let int = grph as? Int {
            self.init(int)
        } else if let num = grph as? Float {
            self.init(num)
        } else {
            fatalError()
        }
    }
    
    var type: GRPHType { SimpleType.integer }
    var state: String { String(self) }
}

extension String: StatefulValue {
    
    init?(byCasting value: GRPHValue) {
        if let str = value as? String {
            self.init(str) // Not a literal
        } else if let val = value as? StatefulValue {
            self.init(val.state)
        } else {
            return nil
        }
    }
    
    var type: GRPHType { SimpleType.string }
    var state: String { "\(self.asLiteral.dropLast())" }
}

extension Float: StatefulValue, GRPHNumber {
    
    init?(byCasting value: GRPHValue) {
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
    
    init(grph: GRPHNumber) {
        if let int = grph as? Int {
            self.init(int)
        } else if let num = grph as? Float {
            self.init(num)
        } else {
            fatalError()
        }
    }
    
    var type: GRPHType { SimpleType.float }
    var state: String { "\(self)F" }
}

extension Bool: StatefulValue {
    
    init?(byCasting value: GRPHValue) {
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
        } else if let arr = value as? GRPHArray {
            self.init(arr.count != 0)
        } else if let opt = value as? GRPHOptional {
            self.init(!opt.isEmpty)
        } else {
            self.init(true)
        }
    }
    
    var type: GRPHType { SimpleType.boolean }
    var state: String { self ? "true" : "false" }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
