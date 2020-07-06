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
#while i < 2000000
\tCircle c = Circle(50,50 pos([10f * i] [10f * i]) color.RED)
\t#if i % 10000 == 0
\t\tlog["Iteration" i c]
\ti += 1
""")
    guard compiler.compile() else {
        return
    }
    print(compiler.wdiuInstructions)
    let runtime = GRPHRuntime(compiler: compiler)
    _ = runtime.run()
    print("Took \(-runtime.timestamp.timeIntervalSinceNow) s")
}

main()
