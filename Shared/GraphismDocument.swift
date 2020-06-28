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

    init(source: String? = nil) {
        if let source = source {
            self.source = source
        } else {
            self.source = ""
        }
        shapes = [GRectangle(positionX: 200, positionY: 100, sizeX: 150, sizeY: 100, paint: .red),
                  GRectangle(positionX: 0, positionY: 0, sizeX: 50, sizeY: 100, paint: .green)]
        print("Creating file")
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
        shapes = [GRectangle(positionX: 200, positionY: 100, sizeX: 150, sizeY: 100, paint: .red)]
        print("Opened \(fileWrapper)")
    }
    
    func write(to fileWrapper: inout FileWrapper, contentType: UTType) throws {
        print("Saving \(fileWrapper)")
        let data = source.data(using: .utf8)!
        fileWrapper = FileWrapper(regularFileWithContents: data)
    }
}
