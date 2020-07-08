//
//  GraphismApp.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI

@main
struct GraphismApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GraphismDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
