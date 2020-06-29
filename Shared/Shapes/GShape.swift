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
    
    var rotation: Int { get set }
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

extension String {
    var asLiteral: String {
        "\"\(self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\t", with: "\\t").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\\", with: "\\\\"))\" "
    }
}

struct GRectangle: RectangularShape, SimpleShape {
    var givenName: String?
    var typeKey: String { "Rectangle" }
    
    var uuid = UUID()
    
    var positionX: Int
    var positionY: Int
    var positionZ: Int = 0
    var sizeX: Int
    var sizeY: Int
    var rotation: Int = 0
    
    var paint: Color
    
    var graphics: AnyView {
        Rectangle()
            .fill(paint)
            .frame(width: CGFloat(sizeX), height: CGFloat(sizeY))
            .rotationEffect(.degrees(Double(rotation)), anchor: .center) // TODO support for rotationCenter
            .position(x: CGFloat(centerX), y: CGFloat(centerY))
            .erased
    }
    
    var stateConstructor: String {
        "Rectangle(\(givenName?.asLiteral ?? "")\(positionX),\(positionY) \(positionZ) \(sizeX),\(sizeY) \(rotation)º \(paint.description.uppercased()))"
    }
}
