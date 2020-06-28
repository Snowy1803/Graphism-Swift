//
//  GraphismDocument.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var grphSource: UTType {
        UTType(importedAs: "fr.orbisec.grph")
    }
}

struct GraphismDocument: FileDocument {
    var source: String

    init(source: String? = nil) {
        if let source = source {
            self.source = source
        } else {
            self.source = ""
        }
    }

    static var readableContentTypes: [UTType] { [.grphSource] }

    init(fileWrapper: FileWrapper, contentType: UTType) throws {
        guard let data = fileWrapper.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        source = string
    }
    
    func write(to fileWrapper: inout FileWrapper, contentType: UTType) throws {
        let data = source.data(using: .utf8)!
        fileWrapper = FileWrapper(regularFileWithContents: data)
    }
}
