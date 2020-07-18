//
//  StandardNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct StandardNameSpace: NameSpace {
    var name: String { "standard" }
    
    var exportedTypes: [GRPHType] {
        SimpleType.allCases
    }
    
    var exportedTypeAliases: [TypeAlias] {
        [
            TypeAlias(name: "farray", type: ArrayType(content: SimpleType.float)),
            TypeAlias(name: "int", type: SimpleType.integer),
            TypeAlias(name: "Square", type: SimpleType.Rectangle),
            TypeAlias(name: "Rect", type: SimpleType.Rectangle),
            TypeAlias(name: "R", type: SimpleType.Rectangle),
            TypeAlias(name: "Ellipse", type: SimpleType.Circle),
            TypeAlias(name: "E", type: SimpleType.Circle),
            TypeAlias(name: "C", type: SimpleType.Circle),
            TypeAlias(name: "L", type: SimpleType.Line),
            TypeAlias(name: "Poly", type: SimpleType.Polygon),
            TypeAlias(name: "P", type: SimpleType.Polygon),
            TypeAlias(name: "T", type: SimpleType.Text),
            TypeAlias(name: "G", type: SimpleType.Group),
            TypeAlias(name: "Back", type: SimpleType.Background)
        ]
    }
    
    var exportedFunctions: [Function] {
        [
            constructorLegacyFunction(type: SimpleType.color),
            constructorLegacyFunction(type: SimpleType.linear),
            constructorLegacyFunction(type: SimpleType.radial),
            constructorLegacyFunction(type: SimpleType.font),
            Function(ns: self, name: "colorFromInt", parameters: [Parameter(name: "value", type: SimpleType.integer)], returnType: SimpleType.color) { context, params in
                let value = params[0] as! Int
                return ColorPaint(integer: value, alpha: true)
            },
            // file manipulation functions removed
            Function(ns: self, name: "stringToInteger", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.integer.optional) { context, params in
                return GRPHOptional(Int(params[0] as! String))
            },
            Function(ns: self, name: "stringToFloat", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.float.optional) { context, params in
                return GRPHOptional(Float(params[0] as! String))
            },
            Function(ns: self, name: "toString", parameters: [Parameter(name: "text...", type: SimpleType.mixed)], returnType: SimpleType.string, varargs: true) { context, params in
                return params.map { $0 ?? "null" }.map(stringRepresentation).joined(separator: " ")
            },
            Function(ns: self, name: "concat", parameters: [Parameter(name: "text...", type: SimpleType.mixed)], returnType: SimpleType.string, varargs: true) { context, params in
                return params.map { $0 ?? "null" }.map(stringRepresentation).joined()
            },
            Function(ns: self, name: "log", parameters: [Parameter(name: "text...", type: SimpleType.mixed)], returnType: SimpleType.string, varargs: true) { context, params in
                let result = params.map { $0 ?? "null" }.map(stringRepresentation).joined(separator: " ")
                printout("Log: \(result)")
                return result
            },
            // getters for fields removed
            Function(ns: self, name: "getCenterPoint", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.pos) { context, params in
                guard let shape = params[0] as? RectangularShape else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of center")
                }
                return shape.center
            },
            Function(ns: self, name: "isFilled", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.pos) { context, params in
                guard let shape = params[0] as? SimpleShape else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of paint")
                }
                return shape.strokeStyle == nil
            },
            Function(ns: self, name: "getPoint", parameters: [Parameter(name: "shape", type: SimpleType.Polygon), Parameter(name: "index", type: SimpleType.integer)], returnType: SimpleType.pos) { context, params in
                let shape = params[0] as! GPolygon
                let index = params[1] as! Int
                guard index < shape.points.count else {
                    throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds")
                }
                return shape.points[index]
            },
            Function(ns: self, name: "integerToRotation", parameters: [Parameter(name: "integer", type: SimpleType.integer)], returnType: SimpleType.rotation) { context, params in
                return Rotation(value: params[0] as! Int)
            },
            Function(ns: self, name: "rotationToInteger", parameters: [Parameter(name: "rotation", type: SimpleType.rotation)], returnType: SimpleType.integer) { context, params in
                return (params[0] as! Rotation).value
            },
            Function(ns: self, name: "getValueInArray", parameters: [Parameter(name: "farray", type: SimpleType.float.inArray), Parameter(name: "index", type: SimpleType.integer)], returnType: SimpleType.float) { context, params in
                let arr = params[0] as! GRPHArray
                let index = params[1] as! Int
                guard index < arr.count else {
                    throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds")
                }
                return arr.wrapped[index]
            },
            Function(ns: self, name: "getArrayLength", parameters: [Parameter(name: "farray", type: SimpleType.mixed.inArray)], returnType: SimpleType.integer) { context, params in
                return (params[0] as! GRPHArray).count
            },
            Function(ns: self, name: "getShape", parameters: [Parameter(name: "index", type: SimpleType.integer)], returnType: SimpleType.shape) { context, params in
                let arr = context.runtime!.image.shapes
                let index = params[0] as! Int
                guard index < arr.count else {
                    throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds")
                }
                return arr[index]
            },
            // getShapeAt, intersects posAround, cloneShape etc missing TODO
            Function(ns: self, name: "getShapeNamed", parameters: [Parameter(name: "name", type: SimpleType.string)], returnType: SimpleType.shape.optional) { context, params in
                let name = params[0] as! String
                return GRPHOptional(context.runtime!.image.shapes.first { $0.givenName == name })
            },
            Function(ns: self, name: "getNumberOfShapes", parameters: [], returnType: SimpleType.integer) { context, params in
                return context.runtime!.image.shapes.count
            },
            Function(ns: self, name: "createPos", parameters: [Parameter(name: "x", type: SimpleType.num), Parameter(name: "y", type: SimpleType.num)], returnType: SimpleType.pos) { context, params in
                return Pos(x: params[0] as? Float ?? Float(params[0] as! Int), y: params[1] as? Float ?? Float(params[1] as! Int))
            },
            Function(ns: self, name: "clippedShape", parameters: [Parameter(name: "shape", type: SimpleType.shape), Parameter(name: "clip", type: SimpleType.shape)], returnType: SimpleType.shape) { context, params in
                return GClip(shape: params[0] as! GShape, clip: params[1] as! GShape)
            },
            Function(ns: self, name: "isInGroup", parameters: [Parameter(name: "group", type: SimpleType.shape), Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.boolean) { context, params in
                return (params[0] as! GGroup).shapes.contains(where: { $0.isEqual(to: params[1]!) })
            },
            Function(ns: self, name: "range", parameters: [Parameter(name: "first", type: SimpleType.integer), Parameter(name: "last", type: SimpleType.integer), Parameter(name: "step", type: SimpleType.integer, optional: true)], returnType: SimpleType.integer.inArray) { context, params in
                let first = params[0] as! Int
                let last = params[1] as! Int
                let step = abs(params[2] as! Int)
                guard step != 0 else {
                    throw GRPHRuntimeError(type: .invalidArgument, message: "step cannot be 0")
                }
                let array = [Int](unsafeUninitializedCapacity: abs(first - last) / step + 1) { buffer, count in
                    var i = first
                    var index = 0
                    while i <= last {
                        buffer[index] = i
                        i += step
                        index += 1
                    }
                    count = index
                }
                return GRPHArray(array, of: SimpleType.integer)
            },
            // == Migrated methods ==
            Function(ns: self, name: "validate", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: nil) { context, params in
                let shape = params[0] as! GShape
                context.runtime?.image.shapes.append(shape)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "validateAll", parameters: [], returnType: nil) { context, params in
                let img = context.runtime!.image
                for v in context.allVariables {
                    if v.name != "back" && v.type.isInstance(of: SimpleType.shape) {
                        img.shapes.append(v.content as! GShape)
                    }
                }
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "unvalidate", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: nil) { context, params in
                let shape = params[0] as! GShape
                context.runtime?.image.shapes.removeAll { $0.isEqual(to: shape) }
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "update", parameters: [], returnType: nil) { context, params in
                context.runtime?.image.willNeedRepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "wait", parameters: [Parameter(name: "time", type: SimpleType.integer)], returnType: nil) { context, params in
                Thread.sleep(forTimeInterval: Double(params[0] as! Int) / 1000)
                return GRPHVoid.void
            },
            Function(ns: self, name: "end", parameters: [], returnType: nil) { context, params in
                throw GRPHExecutionTerminated()
            },
            // LEGACY
            Function(ns: self, name: "setHCentered", parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, params in
                var on = try typeCheck(value: params[0], as: RectangularShape.self)
                on.setHCentered(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "setLeftAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, params in
                var on = try typeCheck(value: params[0], as: RectangularShape.self)
                on.setLeftAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "setRightAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, params in
                var on = try typeCheck(value: params[0], as: RectangularShape.self)
                on.setRightAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "setVCentered", parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, params in
                var on = try typeCheck(value: params[0], as: RectangularShape.self)
                on.setVCentered(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "setTopAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, params in
                var on = try typeCheck(value: params[0], as: RectangularShape.self)
                on.setTopAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Function(ns: self, name: "setBottomAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, params in
                var on = try typeCheck(value: params[0], as: RectangularShape.self)
                on.setBottomAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
        ]
    }
    
    var exportedMethods: [Method] {
        [
            Method(ns: self, name: "rotate", inType: SimpleType.shape, parameters: [Parameter(name: "addRotation", type: SimpleType.rotation)]) { context, on, params in
                var on = try typeCheck(value: on, as: RotatableShape.self)
                on.rotation = on.rotation + (params[0] as! Rotation)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setRotation", inType: SimpleType.shape, parameters: [Parameter(name: "newRotation", type: SimpleType.rotation)]) { context, on, params in
                var on = try typeCheck(value: on, as: RotatableShape.self)
                on.rotation = params[0] as! Rotation
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setRotationCenter", inType: SimpleType.shape, parameters: [Parameter(name: "rotationCenter", type: SimpleType.pos.optional)]) { context, on, params in
                var on = try typeCheck(value: on, as: RotatableShape.self)
                on.rotationCenter = (params[0] as! GRPHOptional).content as? Pos
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "translate", inType: SimpleType.shape, parameters: [Parameter(name: "translation", type: SimpleType.pos)]) { context, on, params in
                var on = try typeCheck(value: on, as: BasicShape.self)
                // Note that translation is supposed to work on ALL shapes, even paths or polygons
                on.position = on.position + (params[0] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setPosition", inType: SimpleType.shape, parameters: [Parameter(name: "newPosition", type: SimpleType.pos)]) { context, on, params in
                var on = try typeCheck(value: on, as: BasicShape.self)
                on.position = params[0] as! Pos
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            // ON SHAPES
            Method(ns: self, name: "setHCentered", inType: SimpleType.shape, parameters: []) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.setHCentered(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setLeftAligned", inType: SimpleType.shape, parameters: []) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.setLeftAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setRightAligned", inType: SimpleType.shape, parameters: []) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.setRightAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setVCentered", inType: SimpleType.shape, parameters: []) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.setVCentered(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setTopAligned", inType: SimpleType.shape, parameters: []) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.setTopAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setBottomAligned", inType: SimpleType.shape, parameters: []) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.setBottomAligned(img: context.runtime!.image)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            // TODO mirror
            Method(ns: self, name: "grow", inType: SimpleType.shape, parameters: [Parameter(name: "extension", type: SimpleType.pos)]) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.size = on.size + (params[0] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setSize", inType: SimpleType.shape, parameters: [Parameter(name: "newSize", type: SimpleType.pos)]) { context, on, params in
                var on = try typeCheck(value: on, as: RectangularShape.self)
                on.size = params[0] as! Pos
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setName", inType: SimpleType.shape, parameters: [Parameter(name: "newName", type: SimpleType.string)]) { context, on, params in
                var shape = on as! GShape
                shape.effectiveName = params[0] as! String
                //context.runtime?.triggerAutorepaint() // only for texts
                return GRPHVoid.void
            },
            Method(ns: self, name: "setPaint", inType: SimpleType.shape, parameters: [Parameter(name: "newPaint", type: SimpleType.paint)]) { context, on, params in
                var on = try typeCheck(value: on, as: SimpleShape.self)
                on.paint = AnyPaint.auto(params[0]!)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setStroke", inType: SimpleType.shape, parameters: [.strokeWidth, .strokeType, .strokeDashArray]) { context, on, params in
                var on = try typeCheck(value: on, as: SimpleShape.self)
                on.strokeStyle = StrokeWrapper(strokeWidth: params.count == 0 ? 5 : params[0] as! Float,
                                               strokeType: params.count <= 1 ? .elongated : params[1] as! Stroke,
                                               strokeDashArray: params.count <= 2 ? GRPHArray(of: SimpleType.float) : params[2] as! GRPHArray)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "filling", inType: SimpleType.shape, parameters: [Parameter(name: "fill", type: SimpleType.boolean)]) { context, on, params in
                var on = try typeCheck(value: on, as: SimpleShape.self)
                let val = params[0] as! Bool
                if val != (on.strokeStyle == nil) {
                    if val {
                        on.strokeStyle = nil
                    } else {
                        on.strokeStyle = StrokeWrapper()
                    }
                }
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setZPos", inType: SimpleType.shape, parameters: [Parameter(name: "zpos", type: SimpleType.integer)]) { context, on, params in
                var shape = on as! GShape
                shape.positionZ = params[0] as! Int
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            // Polygons
            Method(ns: self, name: "addPoint", inType: SimpleType.Polygon, parameters: [Parameter(name: "point", type: SimpleType.pos)]) { context, on, params in
                let shape = on as! GPolygon
                shape.points.append(params[0] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setPoint", inType: SimpleType.Polygon, parameters: [Parameter(name: "index", type: SimpleType.integer), Parameter(name: "point", type: SimpleType.pos)]) { context, on, params in
                let shape = on as! GPolygon
                shape.points[params[0] as! Int] = params[1] as! Pos
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "setPoints", inType: SimpleType.Polygon, parameters: [Parameter(name: "points...", type: SimpleType.pos)], varargs: true) { context, on, params in
                let shape = on as! GPolygon
                shape.points = params.map { $0 as! Pos }
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            // Paths
            Method(ns: self, name: "moveTo", inType: SimpleType.Path, parameters: [Parameter(name: "point", type: SimpleType.pos)]) { context, on, params in
                let shape = on as! GPath
                shape.actions.append(.moveTo)
                shape.points.append(params[0] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "lineTo", inType: SimpleType.Path, parameters: [Parameter(name: "point", type: SimpleType.pos)]) { context, on, params in
                let shape = on as! GPath
                shape.actions.append(.lineTo)
                shape.points.append(params[0] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "quadTo", inType: SimpleType.Path, parameters: [Parameter(name: "ctrl", type: SimpleType.pos), Parameter(name: "point", type: SimpleType.pos)]) { context, on, params in
                let shape = on as! GPath
                shape.actions.append(.quadTo)
                shape.points.append(params[0] as! Pos)
                shape.points.append(params[1] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "cubicTo", inType: SimpleType.Path, parameters: [Parameter(name: "ctrl1", type: SimpleType.pos), Parameter(name: "ctrl2", type: SimpleType.pos), Parameter(name: "point", type: SimpleType.pos)]) { context, on, params in
                let shape = on as! GPath
                shape.actions.append(.cubicTo)
                shape.points.append(params[0] as! Pos)
                shape.points.append(params[1] as! Pos)
                shape.points.append(params[2] as! Pos)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "closePath", inType: SimpleType.Path, parameters: []) { context, on, params in
                let shape = on as! GPath
                shape.actions.append(.closePath)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "addToGroup", inType: SimpleType.Group, parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, on, params in
                let shape = on as! GGroup
                shape.shapes.append(params[0] as! GShape)
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            Method(ns: self, name: "removeFromGroup", inType: SimpleType.Group, parameters: [Parameter(name: "shape", type: SimpleType.shape)]) { context, on, params in
                let shape = on as! GGroup
                let uuid = (params[0] as! GShape).uuid
                shape.shapes.removeAll { $0.uuid == uuid }
                context.runtime?.triggerAutorepaint()
                return GRPHVoid.void
            },
            // TODO selection
        ]
    }
    
    func typeCheck<T>(value: GRPHValue?, as: T.Type) throws -> T {
        if let value = value as? T {
            return value
        } else {
            throw GRPHRuntimeError(type: .typeMismatch, message: "A \(value?.type.string ?? "<not provided>") is not a \(T.self)")
        }
    }
    
    func constructorLegacyFunction(type: GRPHType) -> Function {
        let base = type.constructor!
        return Function(ns: self, name: type.string, parameters: base.parameters, returnType: type, varargs: base.varargs, executable: base.executable)
    }
    
    func stringRepresentation(val: GRPHValue) -> String {
        if let val = val as? CustomStringConvertible {
            return val.description
        } else if let val = val as? StatefulValue {
            return val.state
        }
        return "<@\(val.type.string)>"
    }
}
