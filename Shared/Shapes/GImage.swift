//
//  GImage.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation

class GImage: GGroup, PaintedShape, ResizableShape, ObservableObject {
    var size: Pos
    var paint: AnyPaint
    
    var strokeStyle: StrokeWrapper? // unused
    
    var destroySemaphore = DispatchSemaphore(value: 0)
    private(set) var destroyed = false
    
    init(size: Pos = Pos(x: 640, y: 480), background: AnyPaint = AnyPaint.color(ColorPaint.alpha)) {
        self.size = size
        self.paint = background
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
        "Background(\(size.state) \(paint.state))"
    }
    
    func willNeedRepaint() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Called by the view when the document is closed
    func destroy() {
        destroyed = true
        destroySemaphore.signal()
    }
    
    func toSVG(context: SVGExportContext, into out: inout TextOutputStream) {
        out.writeln("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>")
        out.writeln("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"\(size.x)\" height=\"\(size.y)\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">")
        
        out.writeln("<defs>")
        self.collectSVGDefinitions(context: context, into: &out)
        for shape in shapes {
            shape.collectSVGDefinitions(context: context, into: &out)
        }
        out.writeln("</defs>")
    }
}
