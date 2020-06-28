//
//  Shape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation
import SwiftUI

public protocol GShape {
    var uuid: UUID { get }
    
    var graphics: AnyView { get }
}

public protocol BasicShape: GShape {
    var positionX: Int { get set }
    var positionY: Int { get set }
}

public protocol SimpleShape: GShape {
    var color: Color { get set } // change with custom type
    // stroke or fill?
}

public protocol RectangularShape: BasicShape {
    var sizeX: Int { get set }
    var sizeY: Int { get set }
}

extension RectangularShape {
    var centerX: Int {
        positionX + (sizeX / 2)
    }
    var centerY: Int {
        positionY + (sizeY / 2)
    }
}

extension View {
    var erased: AnyView {
        AnyView(self)
    }
}

struct GRectangle: RectangularShape, SimpleShape {
    var uuid = UUID()
    
    var positionX: Int
    var positionY: Int
    var sizeX: Int
    var sizeY: Int
    
    var color: Color
    
    var graphics: AnyView {
        Rectangle()
            .fill(color)
            .frame(width: CGFloat(sizeX), height: CGFloat(sizeY))
            .position(x: CGFloat(centerX), y: CGFloat(centerY))
            .erased
    }
}
