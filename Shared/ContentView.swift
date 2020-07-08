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
            ShapeListSidebar(document: $document)
            document.image.graphics
        }
    }
}

struct ShapeListSidebar: View {
    @Binding var document: GraphismDocument
    
    var body: some View {
        List {
            ForEach(document.image.shapes, id: \.uuid) { shape in
                Text(shape.effectiveName)
            }
        }.listStyle(SidebarListStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(GraphismDocument()))
    }
}
