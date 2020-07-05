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
    
    var internStrings: [String] = []
    var globalVariables: [Variable] = [] // Add this, back and colors
    var imports: [Importable] = [NameSpaces.namespace(named: "standard")!]
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
            context = GRPHContext(parser: self)
            for lineNumber in 0..<lines.count {
                // Real line
                line0 = lines[lineNumber]
                var line, tline: String
                if line0.isEmpty || line0.hasPrefix("//") {
                    line = ""
                    tline = ""
                    continue
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
                            let p = NameSpaces.namespacedMember(from: params)
                            if p.namespace.isEqual(to: NameSpaces.none) {
                                if let ns = NameSpaces.namespace(named: p.member) {
                                    imports.append(ns)
                                } else {
                                    throw GRPHCompileError(type: .undeclared, message: "Undeclared namespace in import '\(params)'")
                                    // namespace is none if it doesn't exist
                                    // This way, '#import doesntexistlol>stdio' works...
                                    // But '#import doesntexistlol>randomInt' fails with "Undeclared namespace"
                                }
                            }
                            // find function
                            // or find method
                            // or find type
                        
                        case "#typealias":
                            let split = params.split(separator: " ", maxSplits: 1)
                            guard split.count == 2 else {
                                throw GRPHCompileError(type: .parse, message: "Syntax '#typealias newname existing' expected")
                            }
                            guard let type = GRPHTypes.parse(context: context, literal: String(split[1])) else {
                                throw GRPHCompileError(type: .parse, message: "Type '\(split[1])' not found")
                            }
                            guard GRPHTypes.parse(context: context, literal: String(split[0])) == nil else {
                                throw GRPHCompileError(type: .parse, message: "Existing type '\(split[0])' cannot be overridden with a typealias")
                            }
                            imports.append(TypeAlias(name: String(split[0]), type: type))
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
                            guard let index = params.firstIndex(of: "("),
                                  params.hasSuffix(")") else {
                                throw GRPHCompileError(type: .parse, message: "Expected syntax '#throw error(message)'")
                            }
                            let err = params[..<index]
                            guard err.hasSuffix("Exception"),
                                  let error = GRPHRuntimeError.RuntimeExceptionType(rawValue: String(err.dropLast(9))) else {
                                throw GRPHCompileError(type: .undeclared, message: "Error type '\(err)' not found")
                            }
                            let exp = try Expressions.parse(context: context, infer: SimpleType.string, literal: String(params[index...].dropLast().dropFirst()))
                            guard try SimpleType.string.isInstance(context: context, expression: exp) else {
                                throw GRPHCompileError(type: .undeclared, message: "Expected message string in #throw")
                            }
                            try addInstruction(ThrowInstruction(lineNumber: lineNumber, type: error, message: exp))
                        case "#function":
                            break
                        case "#return":
                            break
                        case "#break":
                            try addInstruction(BreakInstruction(lineNumber: lineNumber, type: .break))
                        case "#continue":
                            try addInstruction(BreakInstruction(lineNumber: lineNumber, type: .continue))
                        case "#goto":
                            throw GRPHCompileError(type: .unsupported, message: "#goto has been removed")
                        case "#block":
                            try addInstruction(BlockInstruction(lineNumber: lineNumber))
                        case "#requires":
                            break
                        case "#type":
                            throw GRPHCompileError(type: .unsupported, message: "#type is not available yet")
                        case "#setting":
                            // #setting key value
                            // - selection *true*/false
                            // - generated true/*false* <-- flag "generated automatically; you can save the state over the file with no loss"
                            // - sidebar *true*/false
                            // - propertybar *true*/false
                            // - toolbar *true*/false
                            // - movable *true*/false
                            // - editable *true*/false
                            // - readonly true/*false* -- sets movable, editable
                            // - fullscreen true/*false* -- sets sidebar, propertybar, toolbar
                            break
                        default:
                            print("Warning: Unknown command `\(tline)`; line \(lineNumber + 1). This will get ignored")
                        }
                    } else if tline.hasPrefix("::") {
                        throw GRPHCompileError(type: .unsupported, message: "labels have been removed")
                    } else {
                        // MARK: INSTRUCTIONS
                        // array modification: arr{4} = var
                        // inline func declaration: color randomColor[] = color[randomInteger[256] randomInteger[256] randomInteger[256]]
                        if let result = VariableDeclarationInstruction.pattern.firstMatch(string: tline) {
                            // {integer} arr = (0 1 2 3)
                            try addInstruction(try VariableDeclarationInstruction(lineNumber: lineNumber, groups: result, context: context))
                        }
                        if let result = AssignmentInstruction.pattern.firstMatch(string: tline) {
                            // assignments (=, +=, /= etc)
                            try addInstruction(try AssignmentInstruction(lineNumber: lineNumber, context: context, groups: result))
                        }
                        // method call: validate: shape1
                        // function call: log["test"]
                        // ADD throw GRPHCompileError(type: .parse, message: "Couldn't resolve instruction")
                    }
                } catch let error as GRPHCompileError {
                    print("Compile Error: \(error.type.rawValue)Error: \(error.message); line \(lineNumber + 1)")
                    return false
                } catch {
                    print("NativeError; line \(lineNumber + 1)")
                    print(error.localizedDescription)
                }
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
                globalVariables.append(Variable(name: "$_str\(index!)$", type: SimpleType.string, content: str, final: true))
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
            .replacingOccurrences(of: "\\\\", with: "\\") // TODO "\\n" will get parsed as `\(newline)` instead of `\n`
    }
    
    var wdiuInstructions: String {
        var builder = ""
        for line in instructions {
            builder += line.toString(indent: "\t")
        }
        return builder
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

struct GRPHCompileError: Error {
    var type: CompileErrorType
    var message: String
    
    enum CompileErrorType: String {
        case parse = "Parse"
        case typeMismatch = "Type"
        case undeclared = "Undeclared"
        case invalidArguments = "InvalidArguments"
        case unsupported = "Unsupported"
    }
}

struct GRPHRuntimeError: Error {
    var type: RuntimeExceptionType
    var message: String
    var stack: [String] = []
    
    enum RuntimeExceptionType: String {
        case typeMismatch = "InvalidType"
        case cast = "Cast"
        case inputOutput = "IO"
        case unexpected = "Unexpected"
        case reflection = "Reflection"
        case invalidArgument = "InvalidArgument"
        case permission = "NoPermission"
    }
}
