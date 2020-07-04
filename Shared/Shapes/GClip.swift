//
//  GClip.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI


struct GClip: GShape {
    // rotable
    
    var givenName: String?
    var typeKey: String { "Clip" }
    
    var uuid = UUID()
    
    var positionZ: Int = 0
    
    var shape: GShape
    var clip: GShape
    
    var graphics: AnyView {
        AnyView(shape.graphics.mask(clip.graphics))
    }
    
    var stateDefinitions: String {
        shape.stateDefinitions + clip.stateDefinitions
    }
    
    var stateConstructor: String {
        "clippedShape[\(shape.stateConstructor) \(clip.stateConstructor)]"
    }
    
    var type: GRPHType { SimpleType.shape }
}
