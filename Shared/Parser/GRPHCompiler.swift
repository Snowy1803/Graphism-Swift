//
//  GRPHCompiler.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/07/2020.
//

import Foundation

class GRPHCompiler: GRPHParser {
    static let grphVersion = "1.11"
    static let label = try! NSRegularExpression(pattern: "^[A-Za-z][A-Za-z0-9_]*$")
    static let varNameRequirement = try! NSRegularExpression(pattern: "^[$A-Za-z_][A-Za-z0-9_]*$")
    
    static let allBrackets = try! NSRegularExpression(pattern: "[({\\[\\]})]")
    
    static let internStringPattern = try! NSRegularExpression(pattern: #"(?<!\\)".*?(?<!\\)""#)
    // static let internFilePattern = try! NSRegularExpression(pattern: "(?<!\\\\)'.*?(?<!\\\\)'")
    
    var line0: String = ""
    var blockCount = 0
    
    var internStrings: [String] = []
    var globalVariables: [Variable] = []
    var imports: [Importable] = [NameSpaces.namespace(named: "standard")!]
    var instructions: [Instruction] = []
    var nextLabel: String?
    
    var entireContent: String
    var lines: [String] = []
    var context: GRPHContext!
    
    var settings: [RuntimeSetting: Bool] = [:]
    
    
    var indent = "\t"
    var compilerSettings: Set<CompilerSetting> = []
    
    init(entireContent: String) {
        self.entireContent = entireContent
        // TODO change this to file, or a new type
        globalVariables.append(Variable(name: "this", type: SimpleType.rootThisType, content: "currentDocument", final: true))
        globalVariables.append(Variable(name: "back", type: SimpleType.Background, final: false, compileTime: true))
        globalVariables.append(Variable(name: "WHITE", type: SimpleType.color, content: ColorPaint.white, final: true))
        globalVariables.append(Variable(name: "BLACK", type: SimpleType.color, content: ColorPaint.black, final: true))
        globalVariables.append(Variable(name: "RED", type: SimpleType.color, content: ColorPaint.red, final: true))
        globalVariables.append(Variable(name: "GREEN", type: SimpleType.color, content: ColorPaint.green, final: true))
        globalVariables.append(Variable(name: "BLUE", type: SimpleType.color, content: ColorPaint.blue, final: true))
        globalVariables.append(Variable(name: "ORANGE", type: SimpleType.color, content: ColorPaint.orange, final: true))
        globalVariables.append(Variable(name: "YELLOW", type: SimpleType.color, content: ColorPaint.yellow, final: true))
        globalVariables.append(Variable(name: "PINK", type: SimpleType.color, content: ColorPaint.pink, final: true))
        globalVariables.append(Variable(name: "PURPLE", type: SimpleType.color, content: ColorPaint.purple, final: true))
        globalVariables.append(Variable(name: "AQUA", type: SimpleType.color, content: ColorPaint.aqua, final: true))
        globalVariables.append(Variable(name: "ALPHA", type: SimpleType.color, content: ColorPaint.alpha, final: true))
    }
    
    func dumpWDIU() {
        printout("[WDIU INTERN]")
        for i in 0..<internStrings.count {
            let s = internStrings[i]
            printout("$_str\(i)$ = \(s.replacingOccurrences(of: "&", with: "&&").replacingOccurrences(of: "\n", with: "&n").replacingOccurrences(of: "\r", with: "&r"))\(s.first!)")
        }
        printout("[WDIU START]")
        printout(wdiuInstructions, terminator: "")
        printout("[WDIU END]")
    }
    
    /// Please execute on a secondary thread, as the program
    func compile() -> Bool {
        lines = entireContent.components(separatedBy: "\n")
        context = GRPHContext(parser: self)
        for lineNumber in 0..<lines.count {
            // Real line
            line0 = lines[lineNumber]
            if line0.isEmpty || line0.hasPrefix("//") {
                continue
            }
            
            // Interned & stripped from comments
            let line = internStringLiterals(line: line0).components(separatedBy: "//")[0]
            // Stripped from tabs
            
            // Close blocks
            let tline: String
            if blockCount != 0 {
                var partialLine = line.dropFirst(0)
                var tabs = 0
                while partialLine.hasPrefix(indent) {
                    partialLine = partialLine.dropFirst(indent.count)
                    tabs += 1
                }
                while tabs < blockCount {
                    context = (context as! GRPHBlockContext).parent
                    blockCount -= 1
                }
                tline = transformLine(line: partialLine)
            } else {
                tline = transformLine(line: line)
            }
            
            if tline.isEmpty {
                continue
            }
            
            do {
                
                if tline.hasPrefix("#") {
                    if tline.hasPrefix("#!") {
                        continue // shebang
                    }
                    // MARK: COMMANDS
                    let block = tline.components(separatedBy: " ")[0]
                    let params = tline.dropFirst(block.count).trimmingCharacters(in: .whitespaces)
                    
                    switch block {
                    case "#import", "#using":
                        let p = NameSpaces.namespacedMember(from: params)
                        guard let ns = p.namespace else {
                            throw GRPHCompileError(type: .undeclared, message: "Undeclared namespace in import '\(params)'")
                        }
                        if ns.isEqual(to: NameSpaces.none) {
                            if let ns = NameSpaces.namespace(named: p.member) {
                                imports.append(ns)
                            } else {
                                throw GRPHCompileError(type: .undeclared, message: "Undeclared namespace in import '\(params)'")
                            }
                        } else if let f = Function(imports: [], namespace: ns, name: p.member) {
                            imports.append(f)
                        } else if let t = ns.exportedTypes.first(where: { $0.string == p.member }) {
                            imports.append(t)
                        } else if let t = ns.exportedTypeAliases.first(where: { $0.name == p.member }) {
                            imports.append(t)
                        } else {
                            let cmps = p.member.components(separatedBy: ".")
                            if cmps.count == 2,
                               let type = GRPHTypes.parse(context: context, literal: cmps[0]),
                               let m = Method(imports: [], namespace: ns, name: cmps[1], inType: type) {
                                imports.append(m)
                            } else {
                                throw GRPHCompileError(type: .undeclared, message: "Couldn't import '\(p.member)' from namespace '\(ns.name)'")
                            }
                        }
                    
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
                        try addInstruction(try IfBlock(lineNumber: lineNumber, context: &context, condition: Expressions.parse(context: context, infer: SimpleType.boolean, literal: params)))
                    case "#elseif", "#elif":
                        try addInstruction(try ElseIfBlock(lineNumber: lineNumber, context: &context, condition: Expressions.parse(context: context, infer: SimpleType.boolean, literal: params)))
                    case "#else":
                        guard params.isEmpty else {
                            throw GRPHCompileError(type: .parse, message: "#else doesn't expect arguments")
                        }
                        try addInstruction(ElseBlock(context: &context, lineNumber: lineNumber))
                    case "#while":
                        try addInstruction(try WhileBlock(lineNumber: lineNumber, context: &context, condition: Expressions.parse(context: context, infer: SimpleType.boolean, literal: params)))
                    case "#foreach":
                        let split = params.split(separator: ":", maxSplits: 1)
                        guard split.count == 2 else {
                            throw GRPHCompileError(type: .parse, message: "'#foreach varName : array' syntax expected; array missing")
                        }
                        try addInstruction(try ForEachBlock(lineNumber: lineNumber, context: &context, varName: split[0].trimmingCharacters(in: .whitespaces), array: Expressions.parse(context: context, infer: ArrayType(content: SimpleType.mixed), literal: split[1].trimmingCharacters(in: .whitespaces))))
                    case "#try":
                        try addInstruction(TryBlock(context: &context, lineNumber: lineNumber))
                    case "#catch":
                        let split = params.split(separator: ":", maxSplits: 1)
                        guard split.count == 2 else {
                            throw GRPHCompileError(type: .parse, message: "'#catch varName : errortype' syntax expected; error types missing")
                        }
                        let exs = split[1].components(separatedBy: "|")
                        let trm = try findTryBlock()
                        let currblock = currentBlock
                        var tr: TryBlock
                        if let currblock = currblock {
                            tr = currblock.children[currblock.children.count - trm] as! TryBlock
                        } else {
                            tr = instructions[instructions.count - trm] as! TryBlock
                        }
                        let block = try CatchBlock(lineNumber: lineNumber, context: &context, varName: split[0].trimmingCharacters(in: .whitespaces))
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
                        if let currblock = currblock {
                            currentBlock!.children[currblock.children.count - trm] = tr
                        } else {
                            instructions[instructions.count - trm] = tr
                        }
                        try addInstruction(block)
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
                        try addInstruction(FunctionDeclarationBlock(lineNumber: lineNumber, context: &context, def: params))
                    case "#return":
                        let exp = params.isEmpty ? nil : try Expressions.parse(context: context, infer: nil, literal: params)
                        guard let ctx = context as? GRPHFunctionContext,
                              let block = ctx.inFunction else {
                            throw GRPHCompileError(type: .parse, message: "Cannot use #return outside of a #function block")
                        }
                        let expected = block.generated.returnType
                        if let exp = exp,
                           !expected.isTheVoid {
                            guard try expected.isInstance(context: context, expression: exp) else {
                                throw GRPHCompileError(type: .parse, message: "Expected a #return value of type \(expected), found a \(try exp.getType(context: context, infer: expected))")
                            }
                        } else if exp != nil {
                            throw GRPHCompileError(type: .parse, message: "Cannot #return a value in a void function")
                        } else if !expected.isTheVoid,
                                  block.returnDefault == nil { // expects something, no default return
                            throw GRPHCompileError(type: .parse, message: "No #return value nor default value in non-void function, expected a \(expected)")
                        }
                        try addInstruction(ReturnInstruction(lineNumber: lineNumber, value: exp))
                    case "#break":
                        try addInstruction(BreakInstruction(lineNumber: lineNumber, type: .break, scope: .parse(params: params)))
                    case "#continue":
                        try addInstruction(BreakInstruction(lineNumber: lineNumber, type: .continue, scope: .parse(params: params)))
                    case "#fall":
                        try addInstruction(BreakInstruction(lineNumber: lineNumber, type: .fall, scope: .parse(params: params)))
                    case "#fallthrough":
                        try addInstruction(BreakInstruction(lineNumber: lineNumber, type: .fallthrough, scope: .parse(params: params)))
                    case "#goto":
                        throw GRPHCompileError(type: .unsupported, message: "#goto has been removed")
                    case "#block":
                        try addInstruction(SimpleBlockInstruction(context: &context, lineNumber: lineNumber))
                    case "#requires":
                        let p = params.components(separatedBy: " ")
                        let version: Version
                        if p.count == 1 {
                            version = Version()
                        } else if p.count == 2 {
                            guard let v = Version(description: p[1]) else {
                                throw GRPHCompileError(type: .parse, message: "Couldn't parse version number '\(p[1])'")
                            }
                            version = v
                        } else {
                            throw GRPHCompileError(type: .parse, message: "Expected syntax '#requires plugin version'")
                        }
                        let requires = RequiresInstruction(lineNumber: lineNumber, plugin: p[0], version: version)
                        if blockCount == 0 {
                            try requires.run(context: &context)
                        } else {
                            try addInstruction(requires)
                        }
                    case "#type":
                        throw GRPHCompileError(type: .unsupported, message: "#type requires GRPH 2.0")
                    case "#setting":
                        let split = params.components(separatedBy: " ")
                        guard split.count == 2 else {
                            throw GRPHCompileError(type: .parse, message: "Expected syntax '#setting key value'")
                        }
                        guard let value = Bool(split[1]) else { // only accepts "true" and "false"
                            throw GRPHCompileError(type: .parse, message: "Expected value to be a boolean literal. Dynamic values are not supported.")
                        }
                        if split[0] == "readonly" {
                            settings[.movable] = !value
                            settings[.editable] = !value
                        } else if split[0] == "fullscreen" {
                            settings[.sidebar] = !value
                            settings[.propertybar] = !value
                            settings[.toolbar] = !value
                        } else if let key = RuntimeSetting(rawValue: split[0]) {
                            settings[key] = value
                        } else {
                            throw GRPHCompileError(type: .parse, message: "Key '\(split[0])' not found")
                        }
                        break
                    case "#compiler":
                        let split = params.components(separatedBy: " ")
                        guard split.count == 2 else {
                            throw GRPHCompileError(type: .parse, message: "Expected syntax '#compiler key value'")
                        }
                        switch split[0] {
                        case "indent":
                            let vals = split[1].components(separatedBy: "*")
                            let multiplier: Int?
                            let value: String
                            if vals.count == 2 {
                                guard let int = Int(vals[0]) else {
                                    throw GRPHCompileError(type: .parse, message: "Expected syntax '#compiler indent n*string'")
                                }
                                multiplier = int
                                value = vals[1]
                            } else {
                                multiplier = nil
                                value = split[1]
                            }
                            switch value {
                            case "spaces", "space":
                                indent = String(repeating: " ", count: multiplier ?? 4)
                            case "tabs", "tab", "tabulation", "tabulations":
                                indent = String(repeating: "\t", count: multiplier ?? 1)
                            case "dash", "dashes", "-":
                                indent = String(repeating: "-", count: multiplier ?? 4)
                            case "underscores", "underscore", "_":
                                indent = String(repeating: "_", count: multiplier ?? 4)
                            case "tildes", "tilde", "~":
                                indent = String(repeating: "~", count: multiplier ?? 4)
                            case "uwus":
                                indent = String(repeating: "uwu ", count: multiplier ?? 1)
                            default:
                                if let v = globalVariables.first(where: { $0.name == value }),
                                   let content = v.content as? String {
                                    indent = String(repeating: content, count: multiplier ?? 1)
                                } else {
                                    throw GRPHCompileError(type: .parse, message: "Unknown indent '\(value)'")
                                }
                            }
                        case "altBrackets", "altBracketSet", "alternativeBracketSet":
                            guard let value = Bool(split[1]) else { // only accepts "true" and "false"
                                throw GRPHCompileError(type: .parse, message: "Expected value to be a boolean literal")
                            }
                            if value {
                                compilerSettings.insert(.altBrackets)
                            } else {
                                compilerSettings.remove(.altBrackets)
                            }
                        case "ignore":
                            switch split[1] { // warnings too
                            case "errors", "Error":
                                compilerSettings.insert(.ignoreErrors)
                            case "reset", "nothing":
                                compilerSettings = compilerSettings.filter { $0 == .altBrackets } // only keep other than ignore
                            default:
                                if split[1].hasSuffix("Error"),
                                   let type = GRPHCompileError.CompileErrorType(rawValue: "\(split[1].dropLast(5))") {
                                    compilerSettings.insert(.ignore(type))
                                } else {
                                    printerr("Unknown compile error \(split[1]) asked to ignore")
                                }
                            }
                        default:
                            throw GRPHCompileError(type: .parse, message: "Unknown compiler key '\(split[0])'")
                        }
                        // - maybe disable autounboxing and use postfix "!"
                        break
                    default:
                        printout("Warning: Unknown command `\(tline)`; line \(lineNumber + 1). This will get ignored")
                    }
                } else if tline.hasPrefix("::") {
                    let label = String(tline.dropFirst(2))
                    guard GRPHCompiler.label.firstMatch(string: label) != nil else {
                        throw GRPHCompileError(type: .invalidArguments, message: "Invalid label name '\(label)'")
                    }
                    nextLabel = label
                } else {
                    // MARK: INSTRUCTIONS
                    if let result = ArrayModificationInstruction.pattern.firstMatch(string: tline) {
                        // arr{4} = var
                        try addInstruction(try ArrayModificationInstruction(lineNumber: lineNumber, context: context, groups: result))
                        continue
                    }
                    if FunctionDeclarationBlock.inlineDeclaration.firstMatch(string: tline) != nil {
                        // color randomColor[] = color[randomInteger[256] randomInteger[256] randomInteger[256]]
                        var inner = context!
                        try addNonBlockInstruction(try FunctionDeclarationBlock(lineNumber: lineNumber, context: &inner, def: tline))
                        continue
                    }
                    if let result = VariableDeclarationInstruction.pattern.firstMatch(string: tline) {
                        // {integer} arr = (0 1 2 3)
                        try addInstruction(try VariableDeclarationInstruction(lineNumber: lineNumber, groups: result, context: context))
                        continue
                    }
                    if let result = AssignmentInstruction.pattern.firstMatch(string: tline) {
                        // assignments (=, +=, /= etc)
                        try addInstruction(try AssignmentInstruction(lineNumber: lineNumber, context: context, groups: result))
                        continue
                    }
                    if let result = FunctionExpression.instructionPattern.firstMatch(string: tline) {
                        // validate: shape1
                        let member = NameSpaces.namespacedMember(from: result[1]!)
                        guard let ns = member.namespace else {
                            throw GRPHCompileError(type: .undeclared, message: "Undeclared namespace in namespaced member '\(result[1]!)'")
                        }
                        if let onLiteral = result[2] {
                            // ALWAYS a method
                            let on = try Expressions.parse(context: context, infer: nil, literal: onLiteral)
                            guard let method = Method(imports: imports, namespace: ns, name: member.member, inType: try on.getType(context: context, infer: SimpleType.mixed)) else {
                                throw GRPHCompileError(type: .undeclared, message: "Undeclared method '\(try on.getType(context: context, infer: SimpleType.mixed)).\(result[1]!)'")
                            }
                            try addInstruction(ExpressionInstruction(lineNumber: lineNumber, expression: try MethodExpression(ctx: context, method: method, on: on, values: try Expressions.splitParameters(context: context, in: result[3]!, delimiter: Expressions.space), asInstruction: true)))
                            continue
                        }
                        // function or method on this
                        if let function = Function(imports: imports, namespace: ns, name: member.member) {
                            try addInstruction(ExpressionInstruction(lineNumber: lineNumber, expression: try FunctionExpression(ctx: context, function: function, values: try Expressions.splitParameters(context: context, in: result[3]!, delimiter: Expressions.space), asInstruction: true)))
                        } else if let method = Method(imports: imports, namespace: ns, name: member.member, inType: context.findVariable(named: "this")!.type) {
                            try addInstruction(ExpressionInstruction(lineNumber: lineNumber, expression: try MethodExpression(ctx: context, method: method, on: VariableExpression(name: "this"), values: try Expressions.splitParameters(context: context, in: result[3]!, delimiter: Expressions.space), asInstruction: true)))
                        } else {
                            throw GRPHCompileError(type: .undeclared, message: "Undeclared function or method '\(result[1]!)'")
                        }
                        continue
                    }
                    if let result = FunctionExpression.pattern.firstMatch(string: tline) {
                        // function call: log["test"]
                        let member = NameSpaces.namespacedMember(from: result[1]!)
                        guard let ns = member.namespace else {
                            throw GRPHCompileError(type: .undeclared, message: "Undeclared namespace in namespaced member '\(result[1]!)'")
                        }
                        guard let function = Function(imports: context.parser.imports, namespace: ns, name: member.member) else {
                            throw GRPHCompileError(type: .undeclared, message: "Undeclared function '\(result[1]!)'")
                        }
                        try addInstruction(ExpressionInstruction(lineNumber: lineNumber, expression: try FunctionExpression(ctx: context, function: function, values: try Expressions.splitParameters(context: context, in: result[2]!, delimiter: Expressions.space), asInstruction: true)))
                        continue
                    }
                    throw GRPHCompileError(type: .parse, message: "Couldn't resolve instruction")
                }
            } catch let error as GRPHCompileError {
                if compilerSettings.contains(.ignoreErrors) || compilerSettings.contains(.ignore(error.type)) {
                    continue
                }
                printerr("Compile Error: \(error.type.rawValue)Error: \(error.message); line \(lineNumber + 1)")
                context = nil
                return false
            } catch {
                printerr("NativeError; line \(lineNumber + 1)")
                printerr(error.localizedDescription)
                context = nil
                return false
            }
        }
        context = nil
        return true
    }
    
    func addNonBlockInstruction(_ instruction: Instruction) throws {
        guard nextLabel == nil else {
            // Inline functions
            throw GRPHCompileError(type: .unsupported, message: "Floating labels aren't supported: Labels must precede a block")
        }
        // context.accepts(instruction) // for type contexts
        if blockCount == 0 {
            instructions.append(instruction)
        } else {
            currentBlock!.children.append(instruction)
        }
    }
    
    func addInstruction(_ instruction: Instruction) throws {
        let label = nextLabel
        nextLabel = nil
        if var block = instruction as? BlockInstruction {
            block.label = label
            try addNonBlockInstruction(block)
            blockCount += 1
            return
        } else if label != nil {
            throw GRPHCompileError(type: .unsupported, message: "Floating labels aren't supported: Labels must precede a block")
        }
        try addNonBlockInstruction(instruction)
    }
    
    func findTryBlock(minus: Int = 1) throws -> Int {
        var last: Instruction? = nil
        if blockCount > 0,
           let block = currentBlock {
            if block.children.count >= minus {
                last = block.children[block.children.count - minus]
            }
        } else {
            if instructions.count >= minus {
                last = instructions[instructions.count - minus]
            }
        }
        if last is TryBlock {
            return minus
        } else if last is CatchBlock {
            return try findTryBlock(minus: minus + 1)
        }
        throw GRPHCompileError(type: .parse, message: "#catch requires a #try block before")
    }
    
    func internStringLiterals(line: String) -> String {
        GRPHCompiler.internStringPattern.replaceMatches(in: line) { match in
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
    
    private func transformLine<S: StringProtocol>(line: S) -> String {
        let line = line.trimmingCharacters(in: .whitespaces)
        if compilerSettings.contains(.altBrackets) {
            // #compiler altBrackets true —> replaces ( -> [, [ -> {, { -> ( after internation before parsing
            return GRPHCompiler.allBrackets.replaceMatches(in: line) { bracket in
                switch bracket {
                case "(": return "["
                case ")": return "]"
                case "[": return "{"
                case "]": return "}"
                case "{": return "("
                case "}": return ")"
                default: fatalError()
                }
            }
        }
        return line
    }
    
    var wdiuInstructions: String {
        var builder = ""
        for line in instructions {
            builder += line.toString(indent: "\t")
        }
        return builder
    }
    
    private var currentBlock: BlockInstruction? {
        get {
            lastBlock(in: instructions, max: blockCount)
        }
        set {
            let succeeded = lastBlock(in: &instructions, max: blockCount, new: newValue!)
            assert(succeeded)
        }
    }
    
    private func lastBlock(in arr: [Instruction], max: Int) -> BlockInstruction? {
        if max == 0 {
            return nil
        } else if let curr = arr.last as? BlockInstruction {
            if max == 1 {
                return curr
            }
            return lastBlock(in: curr.children, max: max - 1) ?? curr
        } else {
            return nil
        }
    }
    
    private func lastBlock(in arr: inout [Instruction], max: Int, new: BlockInstruction) -> Bool {
        if max == 1 {
            arr[arr.count - 1] = new
            return true
        }
        if var copy = arr.last as? BlockInstruction {
            if lastBlock(in: &copy.children, max: max - 1, new: new) {
                arr[arr.count - 1] = copy
                return true
            } else {
                arr = new.children
                return true
            }
        } else {
            return false
        }
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
        case redeclaration = "Redeclaration"
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

enum CompilerSetting: Hashable {
    case altBrackets
    case ignoreErrors
    case ignore(GRPHCompileError.CompileErrorType)
}
