//
//  GRPHCompiler.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/07/2020.
//

import Foundation

struct GRPHCompiler: GRPHParser {
    static let grphVersion = "1.11"
    let internStringPattern = try! NSRegularExpression(pattern: #"(?<!\\)".*?(?<!\\)""#)
    // static let internFilePattern = try! NSRegularExpression(pattern: "(?<!\\\\)'.*?(?<!\\\\)'")
    
    var line0: String = ""
    var blocks: [BlockInstruction] = []
    var lineNumber: Int = 0
    
    var internStrings: [String] = []
    var globalVariables: [Variable] = [] // Add this, back and colors
    // ADD var imports: [Importable] = [NameSpace.STANDARD]
    var instructions: [Instruction] = []
    
    var entireContent: String
    var lines: [String] = []
    var timestamp = Date()
    var context: GRPHContext!
    
    // Debugging
    var debugging: Bool = false
    var debugStep: TimeInterval = 0
    
    
    /// Please execute on a secondary thread, as the program
    mutating func compile() -> Bool {
        do {
            lines = entireContent.components(separatedBy: "\n")
            // ADD context = GRPHContext(self) // a copy of self
            lineNumber = 0
            while lineNumber < lines.count {
                // Real line
                line0 = lines[lineNumber]
                var line, tline: String
                if line0.isEmpty || line0.hasPrefix("//") {
                    line = ""
                    tline = ""
                } else {
                    // Interned & stripped from comments
                    line = internStringLiterals(line: line0)
                    line = line.components(separatedBy: "//")[0]
                    // Stripped from tabs
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
                
                do {
                    
                    if tline.hasPrefix("#") {
                        // MARK: COMMANDS
                        let block = tline.components(separatedBy: " ")[0]
                        
                        switch block {
                        case "#import", "#using":
                            let imp = tline.dropFirst(block.count).trimmingCharacters(in: .whitespaces)
                            
                            if imp.contains(">") {
                                // ADD let p = namespacedMemberFromString(imp)
                                // TODO
                            }
                            
                        case "#if":
                            break
                        case "#elseif", "#elif":
                            break
                        case "#else":
                            break
                        case "#while":
                            break
                        case "#foreach":
                            break
                        case "#try":
                            break
                        case "#catch":
                            break
                        case "#throw":
                            break
                        case "#function":
                            break
                        case "#return":
                            break
                        case "#break":
                            break
                        case "#continue":
                            break
                        case "#goto":
                            throw GRPHCompileError(type: .unsupported, message: "#goto has been removed")
                        case "#block":
                            break
                        case "#requires":
                            break
                        case "#type":
                            throw GRPHCompileError(type: .unsupported, message: "#type is not available yet")
                        default:
                            print("Warning: Unknown command `\(tline)`; line \(lineNumber + 1). This will get ignored")
                        }
                    } else if tline.hasPrefix("::") {
                        throw GRPHCompileError(type: .unsupported, message: "labels have been removed")
                    } else {
                        // MARK: INSTRUCTIONS
                        
                    }
                    
                    
                    
                } catch let error as GRPHCompileError {
                    print("Compile Error: \(error.type.rawValue)Error: \(error.message); line \(lineNumber + 1)")
                    return false
                } catch {
                    print("NativeError; line \(lineNumber + 1)")
                    print(error.localizedDescription)
                }
                
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
    
    /// Returns the capture groups of the first match as strings
    func firstMatch(string: String) -> [String?]? {
        guard let result = self.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }
        var matches = [String?]()
        for i in 0...numberOfCaptureGroups {
            if let range = Range(result.range(at: i), in: string) {
                matches.append(String(string[range]))
            } else {
                matches.append(nil)
            }
        }
        return matches
    }
}

public struct GRPHCompileError: Error {
    var type: CompileErrorType
    var message: String
    
    public enum CompileErrorType: String {
        case parse = "Parse"
        case typeMismatch = "Type"
        case undeclared = "Undeclared"
        case invalidArguments = "InvalidArguments"
        case unsupported = "Unsupported"
    }
}
