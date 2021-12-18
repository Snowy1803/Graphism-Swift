//
//  GraphismDocument.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI
import UniformTypeIdentifiers
import GRPHValues
import GRPHRuntime
import GRPHGenerator
import GRPHLexer

extension UTType {
    static let grphSource =
        UTType(exportedAs: "fr.orbisec.grph", conformingTo: .sourceCode)
}

struct GraphismDocument: FileDocument {
    var source: String
    
    var image: GImage
    var delegate = ImageChangeDelegate()
    
    static var readableContentTypes: [UTType] { [.grphSource] }
    static var writableContentTypes: [UTType] { [.grphSource, .svg] }

    init(shapes: [GShape]? = nil) {
        var result: [GShape]
        if let shapes = shapes {
            result = shapes
        } else {
            result = [GRectangle(position: Pos(x: 200, y: 100), size: Pos(x: 150, y: 100), paint: .color(.red)),
                           GRectangle(position: Pos(x: 40, y: 0), size: Pos(x: 50, y: 100), paint: .color(.green), strokeStyle: StrokeWrapper(strokeWidth: 5, strokeType: .rounded, strokeDashArray: GRPHArray([1, 10], of: SimpleType.float))),
                           GRectangle(position: Pos(x: 250, y: 125), size: Pos(x: 50, y: 50), rotation: 45, paint: .color(.yellow)),
                           GCircle(position: Pos(x: 260, y: 135), size: Pos(x: 30, y: 30), paint: .color(.red)),
                           GCircle(position: Pos(x: 10, y: 200), size: Pos(x: 200, y: 150), paint: .linear(.init(from: .blue, direction: .right, to: .green))),
                           GLine(start: Pos(x: 275, y: 150), end: Pos(x: 110, y: 275), paint: .color(.black), strokeStyle: StrokeWrapper(strokeType: .rounded)),
                           GPath(givenName: "heart", points: [Pos(x: 150, y: 210), Pos(x: 75, y: 165), Pos(x: 50, y: 55), Pos(x: 150, y: 110), Pos(x: 250, y: 55), Pos(x: 225, y: 165), Pos(x: 150, y: 210)], actions: [.moveTo, .cubicTo, .cubicTo], paint: .color(.purple)),
                           GClip(shape: GRectangle(position: Pos(x: 300, y: 300), size: Pos(x: 50, y: 50), paint: .radial(.init(centerColor: .orange, externalColor: .red, radius: 1))),
                                 clip: GRectangle(position: Pos(x: 300, y: 300), size: Pos(x: 50, y: 50), rotation: 45, paint: .color(.black))),
                           GPolygon(points: [Pos(x: 200, y: 0), Pos(x: 300, y: 0), Pos(x: 275, y: 30), Pos(x: 300, y: 60), Pos(x: 200, y: 60), Pos(x: 225, y: 30)], paint: .color(.orange))]
        }
        var source = "#setting generated true\n"
        
        for shape in result {
            source += shape.stateDefinitions
            source += "validate: \(shape.stateConstructor)\n"
        }
        self.image = GImage(delegate: delegate.imageDidChange)
        self.source = source
        runGRPH()
    }
    
    init(source: String) {
        self.image = GImage(delegate: delegate.imageDidChange)
        self.source = source
        runGRPH()
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.image = GImage(delegate: delegate.imageDidChange)
        self.source = string
        runGRPH()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        switch configuration.contentType {
        case .grphSource:
            let data = source.data(using: .utf8)!
            return FileWrapper(regularFileWithContents: data)
        case .svg:
            var svg = ""
            image.toSVG(context: SVGExportContext(), into: &svg)
            return FileWrapper(regularFileWithContents: svg.data(using: .utf8)!)
        default:
            preconditionFailure()
        }
    }
    
    func runGRPH() {
        let queue = DispatchQueue(label: "GRPH")
        queue.async {
            guard let runtime = { [source, image] () -> GRPHRuntime? in
                let lexer = GRPHLexer()
                let compiler = GRPHGenerator(lines: lexer.parseDocument(content: source))
                
                guard compiler.compile() else {
                    return nil // TODO show error
                }
                return GRPHRuntime(instructions: compiler.instructions, globalVariables: TopLevelCompilingContext.defaultVariables.filter { !$0.compileTime }, image: image, argv: [])
            }() else {
                return
            }
            _ = runtime.run()
        }
    }
    
    class ImageChangeDelegate: ObservableObject {
        func imageDidChange() {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}
