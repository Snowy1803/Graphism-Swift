//
//  ContentView.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: GraphismDocument

    var body: some View {
        TextEditor(text: $document.source)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(GraphismDocument()))
    }
}
