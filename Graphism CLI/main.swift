//
//  main.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation
import ArgumentParser
import Darwin

struct GraphismCLI: ParsableCommand {
    
    @Flag(name: [.long, .customShort("c")],
          help: "Only compiles the code and checks for compile errors, without running it")
    var onlyCheck: Bool = false
    
    @Flag(help: "Enables WDIU code dump")
    var wdiu = false
    
    @Flag(help: "Enables step-by-step debugging, printing the current line")
    var debug = false
    
    @Option(name: [.long, .customLong("wait")], help: "Step time between instructions, in seconds (0 by default, or infinity when debugging)")
    var step: TimeInterval?
    
    @Argument(help: "The input file to read, as an utf8 encoded grph file")
    var input: String
    
    func run() throws {
        setbuf(stdout, nil)
        let compiler = GRPHCompiler(entireContent: try String(contentsOfFile: input, encoding: .utf8))
        guard compiler.compile() else {
            throw ExitCode.failure
        }
        if wdiu {
            compiler.dumpWDIU()
        }
        if onlyCheck {
            printout("Code compiled successfully")
            throw ExitCode.success
        }
        let runtime = GRPHRuntime(compiler: compiler, image: GImage())
        
        runtime.debugging = debug
        runtime.debugStep = step ?? (debug ? Double.infinity : 0)
        
        let listener = DispatchQueue(label: "bbtce-listener", qos: .background)
        listener.async { listenForBBTCE(runtime: runtime) }
        
        guard runtime.run() else {
            throw ExitCode.failure
        }
    }
    
    func listenForBBTCE(runtime: GRPHRuntime) {
        while let line = readLine() {
            let cmd = line.components(separatedBy: " ")[0]
            switch cmd {
            case "proceed":
                runtime.debugSemaphore.signal()
            case "+debug":
                runtime.debugging = true
                runtime.debugStep = .infinity
            case "-debug":
                runtime.debugging = false
                runtime.debugStep = 0
                runtime.debugSemaphore.signal()
            case "chwait":
                runtime.debugStep = Double(line.dropFirst(7))! / 1000 // Using milliseconds here for consistency with Java Edition
            case "setwait":
                runtime.debugStep = Double(line.dropFirst(8))! // Using seconds here for consistency with command line argument
            case "eval":
                do {
                    guard let context = runtime.context else {
                        printout("[EVAL ERR No context]")
                        break
                    }
                    let e = try Expressions.parse(context: context, infer: nil, literal: String(line.dropFirst(5)))
                    printout("[EVAL OUT \(try e.eval(context: context))]")
                } catch let e as GRPHCompileError {
                    printout("[EVAL ERR \(e.message)]")
                } catch let e as GRPHRuntimeError {
                    printout("[EVAL ERR \(e.message)]")
                } catch {
                    printout("[EVAL ERR Unexpected error]")
                }
            default:
                break
            }
        }
    }
}

GraphismCLI.main()
