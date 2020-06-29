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
    
    var points: [Pos] = []
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
                    path.move(to: points[i].cg)
                    i += 1
                case .lineTo:
                    path.addLine(to: points[i].cg)
                    i += 1
                case .quadTo:
                    path.addQuadCurve(to: points[i + 1].cg, control: points[i].cg)
                    i += 2
                case .cubicTo:
                    path.addCurve(to: points[i + 2].cg, control1: points[i].cg, control2: points[i + 1].cg)
                    i += 3
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
                str += "moveTo path\(uniqueVarName): \(points[i].state)\n"
                i += 1
            case .lineTo:
                str += "lineTo path\(uniqueVarName): \(points[i].state)\n"
                i += 1
            case .quadTo:
                str += "quadTo path\(uniqueVarName): \(points[i].state) \(points[i + 1].state)\n"
                i += 2
            case .cubicTo:
                str += "cubicTo path\(uniqueVarName): \(points[i].state) \(points[i + 1].state) \(points[i + 2].state)\n"
                i += 3
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
