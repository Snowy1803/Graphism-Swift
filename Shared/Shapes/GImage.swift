//
//  GImage.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation
import SwiftUI

class GImage: GGroup, ObservableObject {
    var size: Pos = Pos(x: 640, y: 480)
    var background: AnyPaint = AnyPaint.color(ColorPaint.alpha)
    
    var destroyed = false
    
    init(size: Pos = Pos(x: 640, y: 480), background: AnyPaint = AnyPaint.color(ColorPaint.alpha)) {
        self.size = size
        self.background = background
        super.init(givenName: nil)
    }
    
    override var typeKey: String {
        "Background"
    }
    
    override var type: GRPHType {
        SimpleType.Background
    }
    
    override var stateDefinitions: String {
        "" // never called
    }
    
    override var stateConstructor: String {
        "Background(\(size.state) \(background.state))"
    }
    
    func willNeedRepaint() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Called by the view when the document is closed
    func destroy() {
        destroyed = true
    }
}
