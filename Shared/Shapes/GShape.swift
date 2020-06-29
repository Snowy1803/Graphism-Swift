//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI

public protocol GShape {
    var uuid: UUID { get }
    
    var positionZ: Int { get set }
    var givenName: String? { get set }
    var typeKey: String { get }
    
    var graphics: AnyView { get }
    
    var stateConstructor: String { get }
}

extension GShape {
    var effectiveName: String {
        givenName ?? typeKey // TODO LOCALIZE typeKey
    }
}

public protocol BasicShape: GShape {
    var positionX: Int { get set }
    var positionY: Int { get set }
}

public protocol SimpleShape: GShape {
    var paint: Color { get set } // TODO change with custom PAINT type
    // stroke or fill?
    var strokeStyle: StrokeStyle? { get set }
}

public protocol RotableShape: GShape {
    var rotation: Int { get set }
    // rotation center
}

public protocol RectangularShape: BasicShape {
    var sizeX: Int { get set }
    var sizeY: Int { get set }
}

extension RectangularShape {
    var centerX: Int {
        positionX + (sizeX / 2)
    }
    var centerY: Int {
        positionY + (sizeY / 2)
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
                self.stroke(def.paint, style: style)
            } else {
                self.fill(def.paint)
            }
        }
    }
}

extension StrokeStyle {
    var stateConstructor: String {
        " \(lineWidth)" // TODO joincap & dash array
    }
}

extension String {
    var asLiteral: String {
        "\"\(self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\t", with: "\\t").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\\", with: "\\\\"))\" "
    }
}
