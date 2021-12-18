//
//  GShape+SwiftUI.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation
import SwiftUI
import GRPHValues

extension Rotation {
    var angle: Angle {
        .degrees(Double(value))
    }
}

extension Pos {
    var cg: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

extension ColorPaint {
    func style(shape: GShape) -> Color {
        switch self {
        case .components(red: let red, green: let green, blue: let blue, alpha: let alpha):
            return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
        case .white:
            return .white
        case .gray:
            return .gray
        case .black:
            return .black
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .pink:
            return .pink
        case .purple:
            return .purple
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        }
    }
    
}

extension LinearPaint {
    func style(shape: GShape) -> LinearGradient {
        LinearGradient(gradient: Gradient(colors: [from.style(shape: shape), to.style(shape: shape)]), startPoint: direction.fromPoint, endPoint: direction.toPoint)
    }
}

extension RadialPaint {
    func style(shape: GShape) -> RadialGradient {
        let r: CGFloat
        if let shape = shape as? ResizableShape {
            r = CGFloat(min(shape.size.x, shape.size.y) * radius)
        } else {
            r = CGFloat(20 * radius)
        }
        return RadialGradient(gradient: Gradient(colors: [centerColor.style(shape: shape), externalColor.style(shape: shape)]), center: .init(x: center.cg.x, y: center.cg.y), startRadius: 0, endRadius: r)
    }
}

extension Direction {
    var toPoint: UnitPoint {
        switch self {
        case .right:
            return .trailing
        case .downRight:
            return .bottomTrailing
        case .down:
            return .bottom
        case .downLeft:
            return .bottomLeading
        case .left:
            return .leading
        case .upLeft:
            return .topLeading
        case .up:
            return .top
        case .upRight:
            return .topTrailing
        }
    }
    
    var fromPoint: UnitPoint {
        reverse.toPoint
    }
}

extension Stroke {
    var lineCap: CGLineCap {
        switch self {
        case .elongated:
            return .square
        case .cut:
            return .butt
        case .rounded:
            return .round
        }
    }
    
    var lineJoin: CGLineJoin {
        switch self {
        case .elongated:
            return .miter
        case .cut:
            return .bevel
        case .rounded:
            return .round
        }
    }
}

extension StrokeWrapper {
    var cg: StrokeStyle {
        StrokeStyle(lineWidth: CGFloat(strokeWidth), lineCap: strokeType.lineCap, lineJoin: strokeType.lineJoin, miterLimit: 10, dash: strokeDashArray.wrapped.map { CGFloat($0 as! Float) }, dashPhase: 0)
    }
}

extension JFont {
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
