//
//  GRPHBlockContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 25/07/2020.
//

import Foundation

class GRPHBlockContext: GRPHContext {
    
    let parent: GRPHContext
    let block: BlockInstruction
    
    var variables: [Variable] = []
    /// true if the next else can run, false otherwise
    var canNextRun: Bool = true
    /// true if #break or #continue was called in this block
    var broken: Bool = false
    /// true if #continue was called in this block
    var continued: Bool = false
    /// true if #fallthrough was called in this block
    var mustNextRun: Bool = false
    
    init(parent: GRPHContext, block: BlockInstruction) {
        self.parent = parent
        self.block = block
        super.init(parser: parent.parser)
    }
    
    deinit {
        if runtime?.debugging ?? false {
            for variable in variables {
                printout("[DEBUG -VAR \(variable.name)]")
            }
        }
    }
    
    override var allVariables: [Variable] {
        var vars = parser.globalVariables
        vars.append(contentsOf: variables)
        if let parent = parent as? GRPHBlockContext {
            vars.append(contentsOf: parent.variables)
        }
        return vars
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return parent.findVariable(named: name)
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    override func findVariableInScope(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return nil
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        if global {
            parser.globalVariables.append(variable)
        } else {
            variables.append(variable)
        }
    }
    
    func continueBlock() {
        continued = true
    }
    
    func fallFrom() {
        canNextRun = true
    }
    
    func fallthroughNext() {
        mustNextRun = true
    }
    
    @discardableResult override func breakNearestBlock<T: GRPHBlockContext>(_ type: T.Type, scope: BreakInstruction.BreakScope = .scopes(1)) throws -> T {
        broken = true
        if let value = self as? T {
            switch scope {
            case .label(let label):
                if block.label == label {
                    return value
                }
            case .scopes(let n):
                if n == 1 {
                    return value
                } else {
                    return try parent.breakNearestBlock(type, scope: .scopes(n - 1))
                }
            }
        }
        return try parent.breakNearestBlock(type, scope: scope)
    }
    
    override var inFunction: FunctionDeclarationBlock? { parent.inFunction }
}
