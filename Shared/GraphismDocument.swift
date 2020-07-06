//
//  GraphismDocument.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let grphSource =
        UTType(exportedAs: "fr.orbisec.grph", conformingTo: .sourceCode)
}

struct GraphismDocument: FileDocument {
    var source: String
    
    var shapes: [GShape]

    init(shapes: [GShape]? = nil) {
        if let shapes = shapes {
            self.shapes = shapes
        } else {
            self.shapes = [GRectangle(position: Pos(x: 200, y: 100), size: Pos(x: 150, y: 100), paint: .color(.red)),
                           GRectangle(position: Pos(x: 40, y: 0), size: Pos(x: 50, y: 100), paint: .color(.green), strokeStyle: StrokeWrapper(strokeWidth: 5, strokeType: .rounded, strokeDashArray: GRPHArray([1, 10], of: SimpleType.float))),
                           GRectangle(position: Pos(x: 250, y: 125), size: Pos(x: 50, y: 50), rotation: 45, paint: .color(.yellow)),
                           GCircle(position: Pos(x: 260, y: 135), size: Pos(x: 30, y: 30), paint: .color(.red)),
                           GCircle(position: Pos(x: 10, y: 200), size: Pos(x: 200, y: 150), paint: .linear(.init(from: .blue, direction: .right, to: .green))),
                           GLine(start: Pos(x: 275, y: 150), end: Pos(x: 110, y: 275), paint: .color(.black), strokeStyle: StrokeWrapper(strokeType: .rounded)),
                           GPath(givenName: "heart", points: [Pos(x: 150, y: 210), Pos(x: 75, y: 165), Pos(x: 50, y: 55), Pos(x: 150, y: 110), Pos(x: 250, y: 55), Pos(x: 225, y: 165), Pos(x: 150, y: 210)], actions: [.moveTo, .cubicTo, .cubicTo], paint: .color(.purple)),
                           GClip(shape: GRectangle(position: Pos(x: 300, y: 300), size: Pos(x: 50, y: 50), paint: .radial(.init(centerColor: .orange, externalColor: .red, radius: 25))),
                                 clip: GRectangle(position: Pos(x: 300, y: 300), size: Pos(x: 50, y: 50), rotation: 45, paint: .color(.black))),
                           GPolygon(points: [Pos(x: 200, y: 0), Pos(x: 300, y: 0), Pos(x: 275, y: 30), Pos(x: 300, y: 60), Pos(x: 200, y: 60), Pos(x: 225, y: 30)], paint: .color(.orange))]
        }
        var source = ""
        
        for shape in self.shapes {
            source += shape.stateDefinitions
            source += "validate: \(shape.stateConstructor)\n"
        }
        
        self.source = source
        print("Creating file")
        print(source)
        
        let compiler = GRPHCompiler(entireContent: """
int i = 0
#while i < 1000000
\t#if i * 100000 == 0
\t\t//log["Iteration" i]
\ti += 1
""")
        _ = compiler.compile()
        print(compiler.wdiuInstructions)
        let runtime = GRPHRuntime(compiler: compiler)
        _ = runtime.run()
        print("Took \(-runtime.timestamp.timeIntervalSinceNow) s")
    }

    static var readableContentTypes: [UTType] { [.grphSource] }

    init(fileWrapper: FileWrapper, contentType: UTType) throws {
        print("Opening \(fileWrapper)")
        guard let data = fileWrapper.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            print("Corrupted :/")
            throw CocoaError(.fileReadCorruptFile)
        }
        source = string
        shapes = []
        print("Opened \(fileWrapper)")
    }
    
    func write(to fileWrapper: inout FileWrapper, contentType: UTType) throws {
        print("Saving \(fileWrapper)")
        let data = source.data(using: .utf8)!
        fileWrapper = FileWrapper(regularFileWithContents: data)
    }
}
