//
//  GRPHContextProtocol.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/09/2021.
//

import Foundation

protocol GRPHContextProtocol: AnyObject {
    var imports: [Importable] { get }
}

protocol GRPHCompilerProtocol: AnyObject {
    var imports: [Importable] { get set }
    var hasStrictUnboxing: Bool { get }
    var hasStrictBoxing: Bool { get }
    
    var lineNumber: Int { get }
    var context: CompilingContext! { get set }
}
