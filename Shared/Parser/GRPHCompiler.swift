//
//  GRPHCompiler.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/07/2020.
//

import Foundation

struct GRPHCompiler {
    static let GRPH_VERSION = "1.11"
    
    var line0: String = ""
    var blocks: [BlockInstruction] = []
    var lineNumber: Int = 0
    
    var internStrings: [String] = []
    var variables: [Variable] = [] // Add this, back and colors
    var imports: [Importable] = [NameSpace.STANDARD]
    var instructions: [Instruction] = []
    
    var entireContent: String
    var lines: [String] = []
    var timestamp = Date()
    var context: GRPHContext!
    
    /// Please execute on a secondary thread, as the program
    mutating func compile() -> Bool {
        do {
            lines = entireContent.components(separatedBy: "\n")
            context = GRPHContext(self) // a copy of self
            lineNumber = 0
            while lineNumber < lines.count {
                line0 = lines[lineNumber]
                var line, tline: String
                if line0.isEmpty || line0.hasPrefix("//") {
                    line = ""
                    tline = ""
                } else {
                    line = internStringLiterals(line0)
                    line = line.components(separatedBy: "//")[0]
                    tline = line.trimmingCharacters(in: .whitespaces)
                }
                
                // Close blocks
                if !blocks.isEmpty {
                    let tabs = line.count - line.drop(while: { $0 == "\t" }).count
                    while tabs < blocks.count {
                        blocks.removeLast()
                        context.closeBlock()
                        // TODO change context if going out of function
                    }
                }
                
                // #blocksss
                
                lineNumber += 1
            }
//        } catch {
//            print("Failed")
//            return false
        }
        return true
    }
}
