//
//  GRPHCompiler.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/07/2020.
//

import Foundation

struct GRPHCompiler {
    static let grphVersion = "1.11"
    let internStringPattern = try! NSRegularExpression(pattern: #"(?<!\\)".*?(?<!\\)""#)
    // static let internFilePattern = try! NSRegularExpression(pattern: "(?<!\\\\)'.*?(?<!\\\\)'")
    
    var line0: String = ""
    // ADD var blocks: [BlockInstruction] = []
    var lineNumber: Int = 0
    
    var internStrings: [String] = []
    // ADD var variables: [Variable] = [] // Add this, back and colors
    // ADD var imports: [Importable] = [NameSpace.STANDARD]
    // ADD var instructions: [Instruction] = []
    
    var entireContent: String
    var lines: [String] = []
    var timestamp = Date()
    // ADD var context: GRPHContext!
    
    /// Please execute on a secondary thread, as the program
    mutating func compile() -> Bool {
        do {
            lines = entireContent.components(separatedBy: "\n")
            // ADD context = GRPHContext(self) // a copy of self
            lineNumber = 0
            while lineNumber < lines.count {
                line0 = lines[lineNumber]
                var line, tline: String
                if line0.isEmpty || line0.hasPrefix("//") {
                    line = ""
                    tline = ""
                } else {
                    line = internStringLiterals(line: line0)
                    line = line.components(separatedBy: "//")[0]
                    tline = line.trimmingCharacters(in: .whitespaces)
                }
                
                // Close blocks
                // ADD if !blocks.isEmpty {
                // ADD let tabs = line.count - line.drop(while: { $0 == "\t" }).count
                // ADD while tabs < blocks.count {
                // ADD blocks.removeLast()
                // ADD context.closeBlock()
                        // TODO change context if going out of function
                // ADD }
                // ADD }
                
                // #blocksss
                
                lineNumber += 1
            }
//        } catch {
//            print("Failed")
//            return false
        }
        return true
    }
    
    mutating func internStringLiterals(line: String) -> String {
        internStringPattern.replaceMatches(in: line) { match in
            let str = parseStringLiteral(in: match, delimiter: "\"")
            var index = internStrings.firstIndex(of: "\"\(str)")
            if index == nil {
                index = internStrings.count
                internStrings.append("\"\(str)")
                // ADD variables.add(Constant(name: "$_str\(index!)$", type: SimpleType.string, value: str))
            }
            return "$_str\(index!)$"
        }
        // should also replace files
    }
    
    private func parseStringLiteral(in literal: String, delimiter: Character) -> String {
        String(literal.dropLast().dropFirst())
            .replacingOccurrences(of: "\\\(delimiter)", with: "\(delimiter)")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            //.replacingOccurrences(of: "\\b", with: "\b")
            //.replacingOccurrences(of: "\\f", with: "\f")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}

extension NSRegularExpression {
    func replaceMatches(in string: String, using block: (_ match: String) -> String) -> String {
        var builder = ""
        var last: String.Index?
        self.enumerateMatches(in: string, range: NSRange(string.startIndex..., in: string)) { result, _, _ in
            if let result = result,
               let range = Range(result.range, in: string) {
                
                builder += last == nil ? string[..<range.lowerBound] : string[last!..<range.lowerBound]
                
                // Replacement
                builder += block(String(string[range]))
                
                last = range.upperBound
            }
        }
        guard let end = last else {
            return string // No matches
        }
        builder += string[end...]
        return builder
    }
}

