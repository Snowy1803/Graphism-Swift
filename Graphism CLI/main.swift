//
//  main.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation
import ArgumentParser

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
        let compiler = GRPHCompiler(entireContent: try String(contentsOfFile: input, encoding: .utf8))
        guard compiler.compile() else {
            throw ExitCode.failure
        }
        if wdiu {
            compiler.dumpWDIU()
        }
        if onlyCheck {
            print("Code compiled successfully")
            throw ExitCode.success
        }
        let runtime = GRPHRuntime(compiler: compiler)
        
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
            if line == "proceed" {
                runtime.debugSemaphore.signal()
            }
        }
    }
}

GraphismCLI.main()
