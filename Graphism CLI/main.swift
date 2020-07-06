//
//  main.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

func main() {
    let compiler = GRPHCompiler(entireContent: """
int i = 0
#while i < 1000000
\t#if i * 100000 == 0
\t\t//log["Iteration" i]
\ti += 1
""")
    _ = compiler.compile()
    print(compiler.wdiuInstructions)
    let runtime = GRPHRuntime(compiler: compiler)
    _ = runtime.run()
    print("Took \(-runtime.timestamp.timeIntervalSinceNow) s")
}

main()
