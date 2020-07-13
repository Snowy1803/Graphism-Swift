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
            Function(ns: self, name: "colorFromInt", parameters: [Parameter(name: "value", type: SimpleType.integer)], returnType: SimpleType.color) { context, params in
                let value = params[0] as! Int
                return ColorPaint.components(red: Float((value >> 16) & 0xFF) / 255,
                                             green: Float((value >> 8) & 0xFF) / 255,
                                             blue: Float(value & 0xFF) / 255,
                                             alpha: Float((value >> 24) & 0xFF) / 255)
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
            }
        ]
    }
    
    var exportedMethods: [Method] {
        [
            Method(ns: self, name: "rotate", inType: SimpleType.shape, parameters: [Parameter(name: "addRotation", type: SimpleType.rotation)]) { context, on, params in
                if var on = on as? RotatableShape {
                    on.rotation = on.rotation + (params[0] as! Rotation)
                    context.runtime?.triggerAutorepaint()
                } else {
                    throw GRPHRuntimeError(type: .typeMismatch, message: "A \(on.type) has no rotation")
                }
                return GRPHVoid.void
            }
        ]
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
