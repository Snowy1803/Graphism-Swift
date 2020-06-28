//
//  ContentView.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: GraphismDocument
    
    init(document: Binding<GraphismDocument>) {
        self._document = document
        print("Created ContentView")
    }

    var body: some View {
        NavigationView {
            // ShapeListSidebar()
            ZStack(alignment: .topLeading) {
                ForEach(document.shapes, id: \.uuid) { shape in
                    shape.graphics
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(GraphismDocument()))
    }
}
