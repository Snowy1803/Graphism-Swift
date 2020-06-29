//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


struct GPath: SimpleShape { // Add rotation support
    var givenName: String?
    var typeKey: String { "Path" }
    
    var uuid = UUID()
    
    var points: [Int] = []
    var actions: [PathActions] = []
    var positionZ: Int = 0
    
    var paint: Color
    var strokeStyle: StrokeStyle?
    
    var path: Path {
        Path { path in
            var i = 0
            for action in actions {
                switch action {
                case .moveTo:
                    path.move(to: CGPoint(x: points[i], y: points[i + 1]))
                    i += 2
                case .lineTo:
                    path.addLine(to: CGPoint(x: points[i], y: points[i + 1]))
                    i += 2
                case .quadTo:
                    path.addQuadCurve(to: CGPoint(x: points[i + 2], y: points[i + 3]), control: CGPoint(x: points[i], y: points[i + 1]))
                    i += 4
                case .cubicTo:
                    path.addCurve(to: CGPoint(x: points[i + 4], y: points[i + 5]), control1: CGPoint(x: points[i], y: points[i + 1]), control2: CGPoint(x: points[i + 2], y: points[i + 3]))
                    i += 6
                case .closePath:
                    path.closeSubpath()
                }
            }
            assert(i == points.count, "Path is not valid")
        }
    }
    
    var graphics: AnyView {
        path.applyingFillOrStroke(for: self)
            .erased
    }
    
    var stateDefinitions: String {
        let uniqueVarName = String(uuid.hashValue, radix: 36).dropFirst() // first might be a -
        var str = "Path path\(uniqueVarName) = Path(\(givenName?.asLiteral ?? "")\(positionZ) \(paint.description.uppercased())\(strokeStyle?.stateConstructor ?? ""))\n"
        var i = 0
        for action in actions {
            switch action {
            case .moveTo:
                str += "moveTo path\(uniqueVarName): \(points[i]),\(points[i + 1])\n"
                i += 2
            case .lineTo:
                str += "lineTo path\(uniqueVarName): \(points[i]),\(points[i + 1])\n"
                i += 2
            case .quadTo:
                str += "quadTo path\(uniqueVarName): \(points[i]),\(points[i + 1]) \(points[i + 2]),\(points[i + 3])\n"
                i += 4
            case .cubicTo:
                str += "cubicTo path\(uniqueVarName): \(points[i]),\(points[i + 1]) \(points[i + 2]),\(points[i + 3]) \(points[i + 4]),\(points[i + 5])\n"
                i += 6
            case .closePath:
                str += "closePath path\(uniqueVarName):\n"
            }
        }
        return str
    }
    
    var stateConstructor: String {
        "path\(String(uuid.hashValue, radix: 36).dropFirst())"
    }
}

enum PathActions {
    case moveTo
    case lineTo
    case quadTo
    case cubicTo
    case closePath
}
