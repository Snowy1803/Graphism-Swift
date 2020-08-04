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

protocol GShape: GRPHValue, AnyObject {
    var uuid: UUID { get }
    
    var positionZ: Int { get set }
    var givenName: String? { get set }
    var typeKey: String { get }
    
    #if GRAPHICAL
    var graphics: AnyView { get }
    #endif
    
    var stateDefinitions: String { get }
    var stateConstructor: String { get }
    
    func translate(by diff: Pos)
}

protocol PositionableShape: GShape {
    var position: Pos { get set }
}

protocol PaintedShape: GShape {
    var paint: AnyPaint { get set }
    var strokeStyle: StrokeWrapper? { get set }
}

protocol RotatableShape: GShape {
    var rotation: Rotation { get set }
    var rotationCenter: Pos? { get set }
}

protocol AlignableShape: GShape {
    func setHCentered(img: GImage)
    func setLeftAligned(img: GImage)
    func setRightAligned(img: GImage)
    
    func setVCentered(img: GImage)
    func setTopAligned(img: GImage)
    func setBottomAligned(img: GImage)
}

protocol RectangularShape: PositionableShape, AlignableShape {
    var size: Pos { get set }
}

// Extensions

extension GShape {
    var effectiveName: String {
        get {
            givenName ?? NSLocalizedString(typeKey, comment: "") // will not get localized on CLI version
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

extension PositionableShape {
    func translate(by diff: Pos) {
        position += diff
    }
}

extension RectangularShape {
    var center: Pos {
        get {
            Pos(x: position.x + (size.x / 2), y: position.y + (size.y / 2))
        }
        set {
            position = Pos(x: newValue.x - (size.x / 2), y: newValue.y - (size.y / 2))
        }
    }
    
    func setHCentered(img: GImage) {
        position.x = img.size.x / 2 - size.x / 2
    }
    
    func setLeftAligned(img: GImage) {
        position.x = 0
    }
    
    func setRightAligned(img: GImage) {
        position.x = img.size.x - size.x
    }
    
    func setVCentered(img: GImage) {
        position.y = img.size.y / 2 - size.y / 2
    }
    
    func setTopAligned(img: GImage) {
        position.y = 0
    }
    
    func setBottomAligned(img: GImage) {
        position.y = img.size.y - size.y
    }
}

