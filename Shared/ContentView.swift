//
//  ContentView.swift
//  Shared
//
//  Created by Emil Pedersen on 28/06/2020.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: GraphismDocument
    var image: GImage
    @ObservedObject var delegate: GraphismDocument.ImageChangeDelegate
    @State var destroyOnChange: GImage? = nil
    
    init(document: Binding<GraphismDocument>) {
        self._document = document
        self.image = document.wrappedValue.image
        self.delegate = document.wrappedValue.delegate
        print("Created ContentView")
    }

    var body: some View {
        NavigationView {
            ShapeListSidebar(document: $document)
            document.image.contentGraphics
        }.onChange(of: document.image.uuid) { _ in // If changed from the outside and reloaded automatically
            if let old = destroyOnChange {
                old.destroy()
            }
            destroyOnChange = image
        }.onDisappear { // If closed
            image.destroy()
        }
    }
}

struct ShapeListSidebar: View {
    @Binding var document: GraphismDocument
    
    var body: some View {
        List {
            ForEach(document.image.shapes, id: \.uuid) { shape in
                shape.localizedEffectiveName
            }
        }.listStyle(SidebarListStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(GraphismDocument()))
    }
}
