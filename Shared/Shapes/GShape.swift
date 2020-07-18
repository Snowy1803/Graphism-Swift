//
//  GShape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
#if GRAPHICAL
import SwiftUI
#endif

protocol GShape: GRPHValue {
    var uuid: UUID { get }
    
    var positionZ: Int { get set }
    var givenName: String? { get set }
    var typeKey: String { get }
    
    #if GRAPHICAL
    var graphics: AnyView { get }
    #endif
    
    var stateDefinitions: String { get }
    var stateConstructor: String { get }
}

extension GShape {
    var effectiveName: String {
        get {
            givenName ?? typeKey // TODO LOCALIZE typeKey
        }
        set {
            givenName = newValue
        }
    }
    
    func isEqual(to other: GRPHValue) -> Bool {
        if let shape = other as? GShape {
            return self.uuid == shape.uuid
        }
        return false
    }
}

protocol BasicShape: GShape {
    var position: Pos { get set }
}

protocol SimpleShape: GShape {
    var paint: AnyPaint { get set }
    var strokeStyle: StrokeWrapper? { get set }
}

protocol RotatableShape: GShape {
    var rotation: Rotation { get set }
    var rotationCenter: Pos? { get set }
}

protocol RectangularShape: BasicShape {
    var size: Pos { get set }
}

extension RectangularShape {
    var center: Pos {
        Pos(x: position.x + (size.x / 2), y: position.y + (size.y / 2))
    }
    
    mutating func setHCentered(img: GImage) {
        position.x = img.size.x / 2 - size.x / 2
    }
    
    mutating func setLeftAligned(img: GImage) {
        position.x = 0
    }
    
    mutating func setRightAligned(img: GImage) {
        position.x = img.size.x - size.x
    }
    
    mutating func setVCentered(img: GImage) {
        position.y = img.size.y / 2 - size.y / 2
    }
    
    mutating func setTopAligned(img: GImage) {
        position.y = 0
    }
    
    mutating func setBottomAligned(img: GImage) {
        position.y = img.size.y - size.y
    }
}

extension RotatableShape {
    var currentRotationCenter: Pos {
        rotationCenter ?? Pos(x: 0.5, y: 0.5)
    }
}

extension RotatableShape where Self: RectangularShape {
    var currentRotationCenter: Pos {
        rotationCenter ?? center
    }
}

extension String {
    var asLiteral: String {
        "\"\(self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\t", with: "\\t").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\\", with: "\\\\"))\" "
    }
}
