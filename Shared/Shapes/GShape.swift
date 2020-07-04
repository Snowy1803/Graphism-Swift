//
//  GShape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI

protocol GShape: GRPHValue {
    var uuid: UUID { get }
    
    var positionZ: Int { get set }
    var givenName: String? { get set }
    var typeKey: String { get }
    
    var graphics: AnyView { get }
    
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
    
    func isEqualTo(_ other: GRPHValue) -> Bool {
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
    // rotation center
}

protocol RectangularShape: BasicShape {
    var size: Pos { get set }
}

extension RectangularShape {
    var center: Pos {
        Pos(x: position.x + (size.x / 2), y: position.y + (size.y / 2))
    }
}

extension View {
    var erased: AnyView {
        AnyView(self)
    }
}

extension Shape {
    func applyingFillOrStroke(for def: SimpleShape) -> some View {
        Group {
            if let style = def.strokeStyle {
                applyingStroke(style.cg, paint: def.paint)
            } else {
                switch def.paint {
                case .color(let color):
                    self.fill(color.style)
                case .linear(let linear):
                    self.fill(linear.style)
                case .radial(let radial):
                    self.fill(radial.style)
                }
            }
        }
    }
    
    func applyingStroke(_ stroke: StrokeStyle, paint: AnyPaint) -> some View {
        Group {
            switch paint {
            case .color(let color):
                self.stroke(color.style, style: stroke)
            case .linear(let linear):
                self.stroke(linear.style, style: stroke)
            case .radial(let radial):
                self.stroke(radial.style, style: stroke)
            }
        }
    }
}

extension String {
    var asLiteral: String {
        "\"\(self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\t", with: "\\t").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\\", with: "\\\\"))\" "
    }
}
