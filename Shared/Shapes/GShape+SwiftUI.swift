//
//  GShape+SwiftUI.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation
import SwiftUI


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

extension GRectangle {
    var graphics: AnyView {
        Rectangle()
            .applyingFillOrStroke(for: self)
            .frame(width: CGFloat(size.x), height: CGFloat(size.y))
            .rotationEffect(rotation.angle, anchor: UnitPoint(x: CGFloat(rotationCenter?.x ?? 0.5), y: CGFloat(rotationCenter?.y ?? 0.5)))
            .position(center.cg)
            .erased
    }
}

extension GCircle {
    var graphics: AnyView {
        Ellipse()
            .applyingFillOrStroke(for: self)
            .frame(width: CGFloat(size.x), height: CGFloat(size.y))
            .rotationEffect(rotation.angle, anchor: UnitPoint(x: CGFloat(rotationCenter?.x ?? 0.5), y: CGFloat(rotationCenter?.y ?? 0.5)))
            .position(center.cg)
            .erased
    }
}

extension GLine {
    var path: Path {
        Path { path in
            path.move(to: start.cg)
            path.addLine(to: end.cg)
        }
    }
    
    var graphics: AnyView {
        path.applyingStroke(strokeStyle?.cg ?? StrokeStyle(lineWidth: 5), paint: paint)
            .erased
    }
}

extension GPath {
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
}

extension GPolygon {
    var path: Path {
        Path { path in
            guard points.count >= 2 else {
                return
            }
            path.move(to: points[0].cg)
            for point in points {
                path.addLine(to: point.cg)
            }
            path.closeSubpath()
        }
    }
    
    var graphics: AnyView {
        path.applyingFillOrStroke(for: self)
            .erased
    }
}

extension GClip {
    var graphics: AnyView {
        AnyView(shape.graphics.mask(clip.graphics))
    }
}

extension GGroup {
    var graphics: AnyView {
        ZStack(alignment: .topLeading) {
            ForEach(shapes.sorted(by: { $0.positionZ < $1.positionZ }), id: \.uuid) { shape in
                shape.graphics
            }
        }.erased
    }
}

extension GImage {
    var contentGraphics: AnyView {
        ZStack {
            switch background {
            case .color(let color):
                color.style
            case .linear(let linear):
                linear.style
            case .radial(let radial):
                radial.style
            }
            super.graphics
        }
        .frame(width: size.cg.x, height: size.cg.y)
        .clipped()
        .erased
    }
}

extension GText {
    var uiText: Text {
        font.apply(Text(effectiveName))
    }
    
    var modifiedText: AnyView {
        switch paint {
        case .color(let c):
            return uiText.foregroundColor(c.style).erased
        case .linear(let l):
            return l.style.mask(uiText).erased
        case .radial(let r):
            return r.style.mask(uiText).erased
        }
    }
    
    var graphics: AnyView {
        modifiedText
            .position(position.cg)
            .erased
    }
}