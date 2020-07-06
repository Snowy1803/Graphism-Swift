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
    
    @Flag(help: "Enables WDIU debugging")
    var wdiu = false
    
    @Option(help: "Step time between instructions, in seconds")
    var step: TimeInterval = 0
    
    @Argument(help: "The input file to read, as a utf8 encoded grph file")
    var input: String
    
    func run() throws {
        let compiler = GRPHCompiler(entireContent: try String(contentsOfFile: input, encoding: .utf8))
        guard compiler.compile() else {
            throw ExitCode.failure
        }
        if onlyCheck {
            print("Code compiled successfully")
            throw ExitCode.success
        }
        //print(compiler.wdiuInstructions)
        let runtime = GRPHRuntime(compiler: compiler)
        runtime.debugging = wdiu
        runtime.debugStep = step
        guard runtime.run() else {
            throw ExitCode.failure
        }
    }
}

GraphismCLI.main()
