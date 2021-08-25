//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

enum SimpleType: String, GRPHType, CaseIterable {
    
    case num, integer, float, rotation, pos, boolean, string, paint, color, linear, radial, shape, direction, stroke, /*file, image,*/ font, mixed, void
    
    case Rectangle, Circle, Line, Polygon, /*Image,*/ Text, Path, Group, Background
    
    var string: String {
        rawValue
    }
    
    var supertype: GRPHType {
        return extending ?? SimpleType.mixed
    }
    
    var extending: SimpleType? {
        switch self {
        case .integer, .float:
            return .num
        case .color, .linear, .radial:
            return .paint
        case .Rectangle, .Circle, .Line, .Polygon, .Text, .Path, .Group:
            return .shape // Image --> Rectangle
        case .Background:
            return .Group
        default:
            return nil
        }
    }
    
    var final: Bool {
        switch self {
        case .integer, .float, .color, .linear, .radial, .boolean, .string, .rotation, .pos, .direction, .stroke, .font, .void:
            return true
        case .Rectangle, .Circle, .Line, .Polygon, .Text, .Path, .Group, .Background, .num, .paint, .shape, .mixed:
            return false
        }
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let multi = other as? MultiOrType {
            return isInstance(of: multi.type1) || isInstance(of: multi.type2)
        }
        return other.isTheMixed || other as? SimpleType == self || (extending?.isInstance(of: other) ?? false)
    }
    
    var staticConstants: [TypeConstant] {
        switch self {
        case .color:
            return [TypeConstant(name: "WHITE", type: self,
                                 value: ColorPaint.components(red: 1, green: 1, blue: 1)),
                    TypeConstant(name: "LIGHT_GRAY", type: self,
                                 value: ColorPaint.components(red: 0.75, green: 0.75, blue: 0.75)),
                    TypeConstant(name: "GRAY", type: self,
                                 value: ColorPaint.components(red: 0.5, green: 0.5, blue: 0.5)),
                    TypeConstant(name: "DARK_GRAY", type: self,
                                 value: ColorPaint.components(red: 0.25, green: 0.25, blue: 0.25)),
                    TypeConstant(name: "BLACK", type: self,
                                 value: ColorPaint.components(red: 0, green: 0, blue: 0)),
                    TypeConstant(name: "RED", type: self,
                                 value: ColorPaint.components(red: 1, green: 0, blue: 0)),
                    TypeConstant(name: "GREEN", type: self,
                                 value: ColorPaint.components(red: 0, green: 1, blue: 0)),
                    TypeConstant(name: "BLUE", type: self,
                                 value: ColorPaint.components(red: 0, green: 0, blue: 1)),
                    TypeConstant(name: "CYAN", type: self,
                                 value: ColorPaint.components(red: 0, green: 1, blue: 1)),
                    TypeConstant(name: "MAGENTA", type: self,
                                 value: ColorPaint.components(red: 1, green: 0, blue: 1)),
                    TypeConstant(name: "YELLOW", type: self,
                                 value: ColorPaint.components(red: 1, green: 1, blue: 0)),
                    TypeConstant(name: "ORANGE", type: self,
                                 value: ColorPaint.components(red: 1, green: 0.78, blue: 0)),
                    TypeConstant(name: "BROWN", type: self,
                                 value: ColorPaint.components(red: 0.6, green: 0.2, blue: 0)),
                    TypeConstant(name: "PINK", type: self,
                                 value: ColorPaint.components(red: 1, green: 0.69, blue: 0.69)),
                    TypeConstant(name: "ALPHA", type: self,
                                 value: ColorPaint.components(red: 0, green: 0, blue: 0, alpha: 0)),
                    TypeConstant(name: "SYS_WHITE", type: self,
                                 value: ColorPaint.white),
                    TypeConstant(name: "SYS_GRAY", type: self,
                                 value: ColorPaint.gray),
                    TypeConstant(name: "SYS_BLACK", type: self,
                                 value: ColorPaint.black),
                    TypeConstant(name: "SYS_RED", type: self,
                                 value: ColorPaint.red),
                    TypeConstant(name: "SYS_GREEN", type: self,
                                 value: ColorPaint.green),
                    TypeConstant(name: "SYS_BLUE", type: self,
                                 value: ColorPaint.blue),
                    TypeConstant(name: "SYS_ORANGE", type: self,
                                 value: ColorPaint.orange),
                    TypeConstant(name: "SYS_YELLOW", type: self,
                                 value: ColorPaint.yellow),
                    TypeConstant(name: "SYS_PINK", type: self,
                                 value: ColorPaint.pink),
                    TypeConstant(name: "SYS_PURPLE", type: self,
                                 value: ColorPaint.purple),
                    TypeConstant(name: "SYS_PRIMARY", type: self,
                                 value: ColorPaint.primary),
                    TypeConstant(name: "SYS_SECONDARY", type: self,
                                 value: ColorPaint.secondary)]
        case .float:
            return [TypeConstant(name: "POSITIVE_INFINITY", type: self, value: Float.infinity),
                    TypeConstant(name: "NEGATIVE_INFINITY", type: self, value: -Float.infinity),
                    TypeConstant(name: "NOT_A_NUMBER", type: self, value: Float.nan)]
        case .integer:
            return [TypeConstant(name: "MAX", type: self, value: Int.max),
                    TypeConstant(name: "MIN", type: self, value: Int.min)]
        case .font:
            return [TypeConstant(name: "PLAIN", type: SimpleType.integer, value: JFont.plain),
                    TypeConstant(name: "BOLD", type: SimpleType.integer, value: JFont.bold),
                    TypeConstant(name: "ITALIC", type: SimpleType.integer, value: JFont.italic)]
        case .pos:
            return [TypeConstant(name: "ORIGIN", type: self, value: Pos(x: 0, y: 0))]
        case .stroke:
            return [TypeConstant(name: "ELONGATED", type: self, value: Stroke.elongated),
                    TypeConstant(name: "CUT", type: self, value: Stroke.cut),
                    TypeConstant(name: "ROUNDED", type: self, value: Stroke.rounded)]
        case .direction:
            return [TypeConstant(name: "RIGHT", type: self, value: Direction.right),
                    TypeConstant(name: "DOWN_RIGHT", type: self, value: Direction.downRight),
                    TypeConstant(name: "DOWN", type: self, value: Direction.down),
                    TypeConstant(name: "DOWN_LEFT", type: self, value: Direction.downLeft),
                    TypeConstant(name: "LEFT", type: self, value: Direction.left),
                    TypeConstant(name: "UP_LEFT", type: self, value: Direction.upLeft),
                    TypeConstant(name: "UP", type: self, value: Direction.up),
                    TypeConstant(name: "UP_RIGHT", type: self, value: Direction.upRight)]
        case .void:
            return [TypeConstant(name: "VOID", type: self, value: GRPHVoid.void)]
        default:
            return []
        }
    }
    
    var fields: [Field] {
        switch self {
        case .pos:
            return [KeyPathField(name: "x", type: SimpleType.float, keyPath: \Pos.x),
                    KeyPathField(name: "y", type: SimpleType.float, keyPath: \Pos.y)]
        case .color:
            return [KeyPathField(name: "red", type: SimpleType.integer, keyPath: \ColorPaint.grphRed),
                    KeyPathField(name: "green", type: SimpleType.integer, keyPath: \ColorPaint.grphGreen),
                    KeyPathField(name: "blue", type: SimpleType.integer, keyPath: \ColorPaint.grphBlue),
                    KeyPathField(name: "alpha", type: SimpleType.integer, keyPath: \ColorPaint.grphAlpha),
                    KeyPathField(name: "fred", type: SimpleType.float, keyPath: \ColorPaint.grphFRed),
                    KeyPathField(name: "fgreen", type: SimpleType.float, keyPath: \ColorPaint.grphFGreen),
                    KeyPathField(name: "fblue", type: SimpleType.float, keyPath: \ColorPaint.grphFBlue),
                    KeyPathField(name: "falpha", type: SimpleType.float, keyPath: \ColorPaint.grphFAlpha)]
        case .linear:
            return [KeyPathField(name: "fromColor", type: SimpleType.color, keyPath: \LinearPaint.from),
                    KeyPathField(name: "toColor", type: SimpleType.color, keyPath: \LinearPaint.to),
                    KeyPathField(name: "direction", type: SimpleType.direction, keyPath: \LinearPaint.direction)]
        case .radial:
            return [KeyPathField(name: "fromColor", type: SimpleType.color, keyPath: \RadialPaint.centerColor),
                    KeyPathField(name: "toColor", type: SimpleType.color, keyPath: \RadialPaint.externalColor),
                    KeyPathField(name: "center", type: SimpleType.pos, keyPath: \RadialPaint.center),
                    KeyPathField(name: "radius", type: SimpleType.float, keyPath: \RadialPaint.radius)]
        case .font:
            return [KeyPathField(name: "name", type: SimpleType.string, keyPath: \JFont.grphName),
                    KeyPathField(name: "size", type: SimpleType.integer, keyPath: \JFont.size),
                    KeyPathField(name: "style", type: SimpleType.integer, keyPath: \JFont.weight)]
        // images
        case .rotation:
            return [KeyPathField(name: "value", type: SimpleType.integer, keyPath: \Rotation.value),
                    VirtualField<Rotation>(name: "radians", type: SimpleType.float, getter: { Float($0.value) * (Float.pi / 180) }, setter: { $0.value = Int(($1 as! Float) * (180 / Float.pi)) })]
        case .string:
            return [VirtualField<String>(name: "length", type: SimpleType.integer, getter: { $0.count })]
        case .shape:
            return [ErasedField(name: "name", type: SimpleType.string, getter: { ($0 as! GShape).effectiveName }, setter: {
                let shape = ($0 as! GShape)
                shape.effectiveName = $1 as! String // shapes are always reference types
            }),
            ErasedField(name: "location", type: SimpleType.pos, getter: { ($0 as? PositionableShape)?.position ?? Pos(x: 0, y: 0) }, setter: {
                if let shape = $0 as? PositionableShape {
                    shape.position = $1 as! Pos
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no position")
                }
            }),
            ErasedField(name: "size", type: SimpleType.pos, getter: { ($0 as? RectangularShape)?.size ?? Pos(x: 0, y: 0) }, setter: {
                if let shape = $0 as? ResizableShape {
                    shape.size = $1 as! Pos
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no size")
                }
            }),
            ErasedField(name: "center", type: SimpleType.pos, getter: { ($0 as? RectangularShape)?.center ?? Pos(x: 0, y: 0) }, setter: {
                if let shape = $0 as? RectangularShape {
                    shape.center = $1 as! Pos
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no size")
                }
            }),
            ErasedField(name: "rotationCenter", type: SimpleType.pos.optional, getter: { GRPHOptional(($0 as? RotatableShape)?.rotationCenter) }, setter: {
                if let shape = $0 as? RotatableShape {
                    shape.rotationCenter = ($1 as! GRPHOptional).content as? Pos
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no rotation center")
                }
            }),
            ErasedField(name: "rotation", type: SimpleType.rotation, getter: { ($0 as? RotatableShape)?.rotation ?? Rotation(value: 0) }, setter: {
                if let shape = $0 as? RotatableShape {
                    shape.rotation = $1 as! Rotation
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no rotation")
                }
            }),
            ErasedField(name: "paint", type: SimpleType.paint, getter: { ($0 as? PaintedShape)?.paint.unwrapped ?? ColorPaint.black }, setter: {
                if let shape = $0 as? PaintedShape {
                    shape.paint = AnyPaint.auto($1)
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no paint")
                }
            }),
            ErasedField(name: "strokeWidth", type: SimpleType.float, getter: { ($0 as? PaintedShape)?.strokeStyle?.strokeWidth ?? 5 }, setter: {
                if let shape = $0 as? PaintedShape {
                    var style = shape.strokeStyle ?? StrokeWrapper()
                    style.strokeWidth = $1 as! Float
                    shape.strokeStyle = style
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no stroke")
                }
            }),
            ErasedField(name: "strokeType", type: SimpleType.stroke, getter: { ($0 as? PaintedShape)?.strokeStyle?.strokeType ?? .elongated }, setter: {
                if let shape = $0 as? PaintedShape {
                    var style = shape.strokeStyle ?? StrokeWrapper()
                    style.strokeType = $1 as! Stroke
                    shape.strokeStyle = style
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no stroke")
                }
            }),
            ErasedField(name: "strokeDashArray", type: SimpleType.float.inArray, getter: { ($0 as? PaintedShape)?.strokeStyle?.strokeDashArray ?? GRPHArray([], of: SimpleType.float) }, setter: {
                if let shape = $0 as? PaintedShape {
                    var style = shape.strokeStyle ?? StrokeWrapper()
                    style.strokeDashArray = $1 as! GRPHArray
                    shape.strokeStyle = style
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no stroke")
                }
            }),
            ErasedField(name: "filling", type: SimpleType.boolean, getter: { ($0 as? PaintedShape)?.strokeStyle == nil }, setter: {
                if let shape = $0 as? PaintedShape {
                    shape.strokeStyle = ($1 as! Bool) ? nil : StrokeWrapper()
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \($0.type) has no stroke")
                }
            }),
            ErasedField(name: "zPos", type: SimpleType.integer, getter: { ($0 as! GShape).positionZ }, setter: {
                let shape = ($0 as! GShape)
                shape.positionZ = $1 as! Int
            }),] // TODO blurLevel + add shadow
        case .Text:
            return [KeyPathField(name: "font", type: SimpleType.font, keyPath: \GText.font)]
        case .Polygon:
            return [VirtualField<GPolygon>(name: "points", type: SimpleType.pos.inArray, getter: { GRPHArray($0.points, of: SimpleType.pos) }, setter: { $0.points = ($1 as! GRPHArray).wrapped.map { $0 as! Pos } })]
        case .Group:
            return [VirtualField<GGroup>(name: "shapes", type: SimpleType.shape.inArray, getter: { GRPHArray($0.shapes, of: SimpleType.shape) }, setter: { $0.shapes = ($1 as! GRPHArray).wrapped.map { $0 as! GShape } })]
        default:
            return []
        }
    }
    
    var constructor: Constructor? {
        switch self {
        case .mixed, .num, .integer, .float, .boolean, .string, .paint, .shape, .direction, .stroke:
            return nil
        case .void:
            return Constructor(parameters: [], type: self) { _, _ in GRPHVoid.void }
        case .rotation:
            return Constructor(parameters: [Parameter(name: "degrees", type: SimpleType.integer)], type: self) { context, values in
                return Rotation(value: values[0] as! Int)
            }
        case .pos:
            return Constructor(parameters: [Parameter(name: "x", type: SimpleType.num), Parameter(name: "y", type: SimpleType.num)], type: self) { context, values in
                return Pos(x: values[0] as? Float ?? Float(values[0] as! Int), y: values[1] as? Float ?? Float(values[1] as! Int))
            }
        case .color:
            return Constructor(parameters: [Parameter(name: "red", type: SimpleType.integer), Parameter(name: "green", type: SimpleType.integer), Parameter(name: "blue", type: SimpleType.integer), Parameter(name: "alpha", type: SimpleType.float, optional: true)], type: self) { context, values in
                return ColorPaint.components(red: Float(values[0] as! Int) / 255, green: Float(values[1] as! Int) / 255, blue: Float(values[2] as! Int) / 255, alpha: values.count == 4 ? values[3] as! Float : 1)
            }
        case .linear:
            return Constructor(parameters: [Parameter(name: "from", type: SimpleType.color), Parameter(name: "direction", type: SimpleType.direction), Parameter(name: "to", type: SimpleType.color)], type: self) { context, values in
                return LinearPaint(from: values[0] as! ColorPaint, direction: values[1] as! Direction, to: values[2] as! ColorPaint)
            }
        case .radial:
            return Constructor(parameters: [Parameter(name: "centerColor", type: SimpleType.color), Parameter(name: "center", type: SimpleType.pos, optional: true), Parameter(name: "externalColor", type: SimpleType.color), Parameter(name: "radius", type: SimpleType.float)], type: self) { context, values in
                return RadialPaint(centerColor: values[0] as! ColorPaint, center: values[1] as? Pos ?? Pos(x: 0.5, y: 0.5), externalColor: values[2] as! ColorPaint, radius: values[3] as! Float)
            }
        case .font:
            return Constructor(parameters: [Parameter(name: "name", type: SimpleType.string, optional: true),
                                            Parameter(name: "size", type: SimpleType.integer),
                                            Parameter(name: "style", type: SimpleType.integer, optional: true)], type: self) { context, values in
                return JFont(name: values[0] as? String, size: values[1] as! Int, weight: values.count == 3 ? values[2] as! Int : JFont.plain)
            }
        case .Rectangle:
            return Constructor(parameters: [.shapeName, .pos, .zpos, .size, .rotation, .paint, .strokeWidth, .strokeType, .strokeDashArray], type: self) { context, values in
                return GRectangle(givenName: values[0] as? String,
                                  position: values[1] as! Pos,
                                  positionZ: values[2] as? Int ?? 0,
                                  size: values[3] as! Pos,
                                  rotation: values[4] as? Rotation ?? 0,
                                  paint: AnyPaint.auto(values[5]!),
                                  strokeStyle: values.count == 6 ? nil : StrokeWrapper(strokeWidth: values[6] as? Float ?? 5, strokeType: values[safe: 7] as? Stroke ?? .elongated, strokeDashArray: values[safe: 8] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
            }
        case .Circle:
            return Constructor(parameters: [.shapeName, .pos, .zpos, .size, .rotation, .paint, .strokeWidth, .strokeType, .strokeDashArray], type: self) { context, values in
                return GCircle(givenName: values[0] as? String,
                                  position: values[1] as! Pos,
                                  positionZ: values[2] as? Int ?? 0,
                                  size: values[3] as! Pos,
                                  rotation: values[4] as? Rotation ?? 0,
                                  paint: AnyPaint.auto(values[5]!),
                                  strokeStyle: values.count == 6 ? nil : StrokeWrapper(strokeWidth: values[6] as? Float ?? 5, strokeType: values[safe: 7] as? Stroke ?? .elongated, strokeDashArray: values[safe: 8] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
            }
        case .Line:
            return Constructor(parameters: [.shapeName, .pos1, .pos2, .zpos, .paint, .strokeWidth, .strokeType, .strokeDashArray], type: self) { context, values in
                return GLine(givenName: values[0] as? String,
                                  start: values[1] as! Pos,
                                  end: values[2] as! Pos,
                                  positionZ: values[3] as? Int ?? 0,
                                  paint: AnyPaint.auto(values[4]!),
                                  strokeStyle: StrokeWrapper(strokeWidth: values[safe: 5] as? Float ?? 5, strokeType: values[safe: 6] as? Stroke ?? .elongated, strokeDashArray: values[safe: 7] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
            }
        case .Polygon:
            return Constructor(parameters: [.shapeName, .zpos, .paint, .strokeWidth, .strokeType, .strokeDashArray, Parameter(name: "points...", type: SimpleType.pos, optional: true)], type: self, varargs: true) { context, values in
                return GPolygon(givenName: values[0] as? String,
                                points: values.count > 6 ? values[6...].map { $0 as! Pos } : [],
                                  positionZ: values[1] as? Int ?? 0,
                                  paint: AnyPaint.auto(values[2]!),
                                  strokeStyle: (values[safe: 3] == nil && values[safe: 4] == nil && values[safe: 5] == nil) ? nil : StrokeWrapper(strokeWidth: values[safe: 3] as? Float ?? 5, strokeType: values[safe: 4] as? Stroke ?? .elongated, strokeDashArray: values[safe: 5] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
            }
        case .Text:
            return Constructor(parameters: [Parameter(name: "text", type: SimpleType.string), .pos, .zpos, Parameter(name: "font", type: SimpleType.font | SimpleType.integer), .rotation, .paint], type: self, varargs: true) { context, values in
                return GText(givenName: (values[0] as! String),
                             position: values[1] as! Pos,
                             positionZ: values[2] as? Int ?? 0,
                             font: values[3] as? JFont ?? JFont(size: values[3] as! Int),
                             rotation: values[4] as? Rotation ?? 0,
                             paint: AnyPaint.auto(values[5]!))
            }
        case .Path:
            return Constructor(parameters: [.shapeName, .zpos, .rotation, .paint, .strokeWidth, .strokeType, .strokeDashArray], type: self) { context, values in
                return GPath(givenName: values[0] as? String,
                                  positionZ: values[1] as? Int ?? 0,
                                  rotation: values[2] as? Rotation ?? 0,
                                  paint: AnyPaint.auto(values[3]!),
                                  strokeStyle: values.count == 4 ? nil : StrokeWrapper(strokeWidth: values[4] as? Float ?? 5, strokeType: values[safe: 5] as? Stroke ?? .elongated, strokeDashArray: values[safe: 6] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
            }
        case .Group:
            return Constructor(parameters: [.shapeName, .zpos, .rotation, Parameter(name: "shapes...", type: SimpleType.shape, optional: true)], type: self, varargs: true) { context, values in
                return GGroup(givenName: values[0] as? String,
                              positionZ: values[1] as? Int ?? 0,
                              rotation: values[2] as? Rotation ?? 0,
                              shapes: values.count > 3 ? values[3...].map { $0 as! GShape } : [])
            }
        case .Background:
            return Constructor(parameters: [.size, .paint], type: self) { context, values in
                return GImage(size: values[0] as! Pos, background: AnyPaint.auto(values[1]!))
            }
        }
    }
}

extension SimpleType {
    static var rootThisType: SimpleType { SimpleType.string }
}
