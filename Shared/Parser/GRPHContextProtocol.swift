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
