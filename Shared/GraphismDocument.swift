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
            self.shapes = [GRectangle(position: Pos(x: 200, y: 100), size: Pos(x: 150, y: 100), paint: .red),
                           GRectangle(position: Pos(x: 40, y: 0), size: Pos(x: 50, y: 100), paint: .green, strokeStyle: StrokeStyle(lineWidth: 5)),
                           GRectangle(position: Pos(x: 250, y: 125), size: Pos(x: 50, y: 50), rotation: 45, paint: .yellow),
                           GCircle(position: Pos(x: 260, y: 135), size: Pos(x: 30, y: 30), paint: .red),
                           GCircle(position: Pos(x: 10, y: 200), size: Pos(x: 200, y: 150), paint: .blue),
                           GLine(startX: 275, startY: 150, endX: 110, endY: 275, paint: .black, strokeStyle: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)),
                           GPath(givenName: "heart", points: [150, 210, 75, 165, 50, 55, 150, 110, 250, 55, 225, 165, 150, 210], actions: [.moveTo, .cubicTo, .cubicTo], paint: .purple),
                           GClip(shape: GRectangle(position: Pos(x: 300, y: 300), size: Pos(x: 50, y: 50), paint: .pink),
                                 clip: GRectangle(position: Pos(x: 300, y: 300), size: Pos(x: 50, y: 50), rotation: 45, paint: .black)),
                           GPolygon(points: [200, 0, 300, 0, 275, 30, 300, 60, 200, 60, 225, 30], paint: .orange)]
        }
        var source = ""
        
        for shape in self.shapes {
            source += shape.stateDefinitions
            source += "validate: \(shape.stateConstructor)\n"
        }
        
        self.source = source
        print("Creating file")
        print(source)
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
