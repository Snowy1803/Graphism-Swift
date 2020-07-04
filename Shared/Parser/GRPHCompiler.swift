//
//  GRPHCompiler.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/07/2020.
//

import Foundation

class GRPHCompiler: GRPHParser {
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
    
    init(entireContent: String) {
        self.entireContent = entireContent
    }
    
    
    /// Please execute on a secondary thread, as the program
    func compile() -> Bool {
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
                        let params = tline.dropFirst(block.count).trimmingCharacters(in: .whitespaces)
                        
                        switch block {
                        case "#import", "#using":
                            if params.contains(">") {
                                // ADD let p = namespacedMemberFromString(imp)
                                // TODO
                            }
                            
                        case "#if":
                            try addInstruction(try IfBlock(lineNumber: lineNumber, context: context, condition: Expressions.parse(context: context, infer: SimpleType.boolean, literal: params)))
                        case "#elseif", "#elif":
                            try addInstruction(try ElseIfBlock(lineNumber: lineNumber, context: context, condition: Expressions.parse(context: context, infer: SimpleType.boolean, literal: params)))
                        case "#else":
                            guard params.isEmpty else {
                                throw GRPHCompileError(type: .parse, message: "#else doesn't expect arguments")
                            }
                            try addInstruction(ElseBlock(lineNumber: lineNumber))
                        case "#while":
                            try addInstruction(try WhileBlock(lineNumber: lineNumber, context: context, condition: Expressions.parse(context: context, infer: SimpleType.boolean, literal: params)))
                        case "#foreach":
                            let split = params.split(separator: ":", maxSplits: 1)
                            guard split.count == 2 else {
                                throw GRPHCompileError(type: .parse, message: "'#foreach varName : array' syntax expected; array missing")
                            }
                            try addInstruction(try ForBlock(lineNumber: lineNumber, context: context, varName: split[0].trimmingCharacters(in: .whitespaces), array: Expressions.parse(context: context, infer: ArrayType(content: SimpleType.mixed), literal: split[1].trimmingCharacters(in: .whitespaces))))
                        case "#try":
                            try addInstruction(TryBlock(lineNumber: lineNumber))
                        case "#catch":
                            let split = params.split(separator: ":", maxSplits: 1)
                            guard split.count == 2 else {
                                throw GRPHCompileError(type: .parse, message: "'#catch varName : errortype' syntax expected; error types missing")
                            }
                            let block = try CatchBlock(lineNumber: lineNumber, context: context, varName: split[0].trimmingCharacters(in: .whitespaces))
                            let exs = split[1].components(separatedBy: "|")
                            let tr: TryBlock = try findTryBlock()
                            for rawErr in exs {
                                let error = rawErr.trimmingCharacters(in: .whitespaces)
                                if error == "Exception" {
                                    tr.catches[nil] = block
                                    block.addError(type: "Exception")
                                } else if error.hasSuffix("Exception"),
                                          let err = GRPHRuntimeError.RuntimeExceptionType(rawValue: String(error.dropLast(9))) {
                                    guard tr.catches[err] == nil else {
                                        continue
                                    }
                                    tr.catches[err] = block
                                    block.addError(type: "\(err.rawValue)Exception")
                                } else {
                                    throw GRPHCompileError(type: .undeclared, message: "Error '\(error)' not found")
                                }
                            }
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
    
    func addNonBlockInstruction(_ instruction: Instruction) {
        if let block = blocks.last {
            block.children.append(instruction)
        } else {
            instructions.append(instruction)
        }
    }
    
    func addInstruction(_ instruction: Instruction) throws {
        addNonBlockInstruction(instruction)
        // context.accepts(instruction) // for types ig
        /* ADD if let function = instruction as? FunctionDeclarationBlock {
            blocks.append(instruction)
        } else */if let block = instruction as? BlockInstruction {
            blocks.append(block)
            context.inBlock(block: block)
        }
    }
    
    func findTryBlock(minus: Int = 1) throws -> TryBlock {
        var last: Instruction? = nil
        if let block = blocks.last {
            if block.children.count >= minus {
                last = block.children[block.children.count - minus]
            }
        } else {
            if instructions.count >= minus {
                last = instructions[instructions.count - minus]
            }
        }
        if let last = last as? TryBlock {
            return last
        } else if last is CatchBlock {
            return try findTryBlock(minus: minus + 1)
        }
        throw GRPHCompileError(type: .parse, message: "#catch requires a #try block before")
    }
    
    func internStringLiterals(line: String) -> String {
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
    // Only throws if block throws, but can't use rethrows because NSRegularExpression.enumerateMatches doesn't rethrow
    func allMatches(in string: String, using block: (_ match: Range<String.Index>) throws -> Void) throws {
        var err: Error?
        self.enumerateMatches(in: string, range: NSRange(string.startIndex..., in: string)) { result, _, stop in
            if let result = result,
               let range = Range(result.range, in: string) {
                do {
                    try block(range)
                } catch let error {
                    err = error
                    stop.pointee = true
                }
            }
        }
        if let err = err {
            throw err
        }
    }
    
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

public struct GRPHRuntimeError: Error {
    var type: RuntimeExceptionType
    var message: String
    var stack: [String] = []
    
    public enum RuntimeExceptionType: String {
        case typeMismatch = "InvalidType"
        case cast = "Cast"
        case inputOutput = "IO"
        case unexpected = "Unexpected"
        case reflection = "Reflection"
        case invalidArgument = "InvalidArgument"
        case permission = "NoPermission"
    }
}
