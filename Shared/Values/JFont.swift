//
//  JFont.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation
import SwiftUI

struct JFont: StatefulValue, Equatable {
    static let plain = 0
    static let bold = 1
    static let italic = 2
    
    var type: GRPHType { SimpleType.font }
    
    var name: String?
    var size: Int
    var weight: Int = JFont.plain
    
    var bold: Bool { (weight & JFont.bold) == JFont.bold }
    var italic: Bool { (weight & JFont.italic) == JFont.italic }
    
    var grphName: String {
        get {
            name ?? "San Francisco"
        }
        set {
            name = newValue
        }
    }
    
    var state: String {
        "font(\(name?.asLiteral ?? "")\(size) \(weight))"
    }
    
    var cg: Font {
        if let name = name {
            return .custom(name, size: CGFloat(size))
        }
        return .system(size: CGFloat(size))
    }
    
    func apply(_ text : Text) -> Text {
        let text = text.font(cg).fontWeight(bold ? .bold : .regular)
        if italic {
            return text.italic()
        }
        return text
    }
}