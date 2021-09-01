//
//  GraphismTests.swift
//  GraphismTests
//
//  Created by Emil Pedersen on 30/06/2020.
//

import XCTest

class GraphismTests: XCTestCase {
    
    var context: CompilingContext!
    var compiler: GRPHCompiler!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        compiler = GRPHCompiler(entireContent: "")
        context = TopLevelCompilingContext(compiler: compiler)
        compiler.context = context
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTypeParsing() throws {
        parseType("string")
        parseType("<int>", expected: "integer")
        parseType("{string|integer}")
        parseType("farray", expected: "{float}")
        parseType("<string|integer>?")
        parseType("string|integer?")
        parseType("<Rectangle?|Circle?>?")
        parseType("{{{farray}}}", expected: "{{{{float}}}}")
        parseType("{string|paint|float}")
        parseType("{string|{paint}|{float}}")
        parseType("string|paint|float?")
        parseType("funcref")
        parseType("funcref<void><>")
        parseType("funcref<string><string+integer>")
        parseType("funcref<color><int+int+int>", expected: "funcref<color><integer+integer+integer>")
        parseType("funcref<void><>|funcref<integer><>|funcref<float><>?")
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "intreger"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<>float"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "float{}"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<float><>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "{num}|"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "|<boolean>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<>|<boolean>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: ""))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "funcref<>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "funcref<><string>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "funcref<string+string><string>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "funcref<string><string><string>"))
    }
    
    func parseType(_ literal: String, expected: String? = nil) {
        XCTAssertEqual(expected ?? literal, GRPHTypes.parse(context: context, literal: literal)?.string)
    }
    
    func testTypeBoxing() throws {
        checkType(of: 12345 as Int, expected: SimpleType.integer)
        checkType(of: 12.345 as Float, expected: SimpleType.float)
        checkType(of: 12.345 as Float, expected: OptionalType(wrapped: SimpleType.float))
        checkType(of: "Nothing", expected: OptionalType(wrapped: OptionalType(wrapped: SimpleType.string)))
        checkWrongType(of: "Bad boi", expected: OptionalType(wrapped: OptionalType(wrapped: SimpleType.float)))
        checkType(of: GRPHOptional.null, expected: OptionalType(wrapped: SimpleType.float))
        checkType(of: GRPHOptional.null, expected: OptionalType(wrapped: SimpleType.string))
        checkWrongType(of: GRPHOptional.some(12.345 as Float), expected: OptionalType(wrapped: SimpleType.string))
        checkType(of: GRPHOptional.some(12.345 as Float), expected: SimpleType.float)
        checkWrongType(of: GRPHOptional.null, expected: SimpleType.float)
    }
    
    func checkType(of value: GRPHValue, expected: GRPHType) {
        XCTAssertEqual(GRPHTypes.type(of: value, expected: expected).string, expected.string)
    }
    
    func checkWrongType(of value: GRPHValue, expected: GRPHType) {
        XCTAssertNotEqual(GRPHTypes.type(of: value, expected: expected).string, expected.string)
    }
    
    func testInternation() throws {
        XCTAssertEqual(compiler.internStringLiterals(line: "nothing to see here..."), "nothing to see here...")
        XCTAssertEqual(compiler.internStringLiterals(line: #"string str = "hello world""#), "string str = $_str0$")
        XCTAssertEqual(compiler.internStringLiterals(line: #"string sam = "hello world" + str"#), "string sam = $_str0$ + str")
        XCTAssertEqual(compiler.internStringLiterals(line: #"string oth = "another str""#), "string oth = $_str1$")
        XCTAssertEqual(compiler.internStringLiterals(line: #"string lol = "hello world""#), "string lol = $_str0$")
        XCTAssertEqual(compiler.internStringLiterals(line: #"string now = "he\"llo\" w\"o\"rld""#), "string now = $_str2$")
        XCTAssertEqual(compiler.internStringLiterals(line: #"string mul = "first " + "second""#), "string mul = $_str3$ + $_str4$")
        
        XCTAssertEqual(compiler.internStrings.debugDescription, #"["hello world", "another str", "he\"llo\" w\"o\"rld", "first ", "second"]"#)
    }
    
    func testExpressionParsing() throws {
        context.addVariable(Variable(name: "var", type: SimpleType.integer, final: false, compileTime: true), global: true)
        
        // ENUMS
        
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.boolean, literal: "true").string, "true")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.boolean, literal: "false").string, "false")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.boolean, literal: "[true]").string, "true")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.stroke, literal: "elongated").string, "elongated")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.stroke, literal: "[cut]").string, "cut")
        
        // POS
        
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.pos, literal: "5,0").string, "5.0,0.0")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.pos, literal: "3,-6.5").string, "3.0,-6.5")
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.pos, literal: "3.0.0,4"))
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.pos, literal: "-5,-42").string, "-5.0,-42.0")
        
        // NUMERICS
        
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.rotation, literal: "-5°").string, "-5°")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.rotation, literal: "175º").string, "175°")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "42").string, "42")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "-2").string, "-2")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "-2.5").string, "-2.5F")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "2.5f").string, "2.5F")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "2F").string, "2.0F")
        
        // ARRAY VALUE
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "arr{5}").string, "arr{5}")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "arr{var}").string, "arr{var}")
        
        XCTAssertEqual(try Expressions.parse(context: context, infer: ArrayType(content: SimpleType.float), literal: "<float>{5, 3, 2 ,6}").string, "<float>{5, 3, 2, 6}")
        XCTAssertEqual(try Expressions.parse(context: context, infer: ArrayType(content: SimpleType.integer), literal: "{5,3,2, 6}").string, "<integer>{5, 3, 2, 6}")
        XCTAssertEqual(try Expressions.parse(context: context, infer: ArrayType(content: SimpleType.string), literal: "{}").string, "<string>{}")
        
        // CASTS
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.boolean, literal: "var as boolean").string, "var as boolean")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.boolean, literal: "var is <integer|paint>").string, "var is integer|paint")
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.boolean, literal: "var as invalidtype"))
        
        // Binary operators
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "5.2 + 2.8").string, "5.2F + 2.8F")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "32.0/8").string, "32.0F / 8")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "32F / 8 * 7 + 42 - 69 % 3").string,
                       "[[[32.0F / 8] * 7] + 42] - [69 % 3]")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "32 == 42 || 67 == 69 || [96 != 420 && 2 > 1]").string, "[32 == 42] || [67 == 69] || [[96 != 420] && [2 > 1]]")
        
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "-var + 5").string, "-var + 5")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "-5 + var").string, "-5 + var")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "-[5 + var]").string, "-[5 + var]")
        
        // FIELDS
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.color, literal: "color.BLACK").string, "color.BLACK")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "float.NOT_A_NUMBER").string, "float.NOT_A_NUMBER")
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.float, literal: "float.DOESNTEXIST"))
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.float, literal: "doesntexist.CONST"))
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "[var as rotation].value").string, "[var as rotation].value")
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.float, literal: "[var as rotation].doesntexist"))
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.float, literal: "doesntexist.doesntexist"))
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.string, literal: "[var as Background].name").string, "[var as Background].name")
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.integer, literal: "[var as {string}].length").string, "[var as {string}].length")
    }
    
    func testCasts() throws {
        try cast(literal: "1 as string", expected: "1")
        try cast(literal: "1 as string?", expected: "Optional[1]")
        try cast(literal: "3° as integer", expected: "3")
        context.addVariable(Variable(name: "ff", type: SimpleType.string, content: "45", final: true), global: true)
        context.addVariable(Variable(name: "col", type: SimpleType.string, content: "#ff0000", final: true), global: true)
        context.addVariable(Variable(name: "zzz", type: SimpleType.string, content: "0zZZZ", final: true), global: true)
        try cast(literal: "ff as integer", expected: "45")
        try cast(literal: "col as color", expected: "components(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)")
        try cast(literal: "zzz as int", expected: "46655")
        try cast(literal: "{mixed}(ff col zzz) as <{string}>", expected: ##"<string>{"45", "#ff0000", "0zZZZ"}"##)
        try cast(literal: "3 as string as rotation as float", expected: "3.0")
        try cast(literal: "color.RED as paint", expected: "red")
        try cast(literal: "ff as paint|string", expected: "45")
        try cast(literal: "5 as rotation|float", expected: "Rotation(value: 5)")
        try cast(literal: "5f as rotation|float", expected: "5.0")
        try cast(literal: "5 as rotation|float|integer|float", expected: "5")
        
        try cast(literal: "5 as? float", expected: "Optional[5.0]")
        try cast(literal: "5.0 as! float", expected: "5.0")
        try cast(literal: "color.RED as? float", expected: "null")
        try cast(literal: "color.RED as?! float", expected: "null")
        try cast(literal: "5.0 as?! float?", expected: "Optional[Optional[5.0]]")
        try cast(literal: "5 as?! float?", expected: "null")
        compiler.imports.append(TypeAlias(name: "firstFuncType", type: try XCTUnwrap(GRPHTypes.parse(context: context, literal: "funcref<num><integer+num>"))))
        compiler.imports.append(TypeAlias(name: "secondFuncType", type: try XCTUnwrap(GRPHTypes.parse(context: context, literal: "funcref<mixed><integer+integer>"))))
        try cast(literal: "firstFuncType(5) is secondFuncType", expected: "true")
        try cast(literal: "secondFuncType(5) is firstFuncType", expected: "false")
        
        let runtime = GRPHRuntime(compiler: compiler, image: GImage())
        let ctx = TopLevelRuntimeContext(runtime: runtime)
        
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.mixed, literal: "color.RED as! float").eval(context: ctx))
        XCTAssertThrowsError(try Expressions.parse(context: context, infer: SimpleType.mixed, literal: "color.RED as float").eval(context: ctx))
    }
    
    func cast(literal: String, expected: String) throws {
        let exp = try Expressions.parse(context: context, infer: SimpleType.mixed, literal: literal)
        
        let runtime = GRPHRuntime(compiler: compiler, image: GImage())
        runtime.initialGlobalVariables = context.allVariables
        let ctx = TopLevelRuntimeContext(runtime: runtime)
        
        XCTAssertEqual("\(try exp.eval(context: ctx))", expected)
    }
    
    func testSampleProgram() {
        compiler = GRPHCompiler(entireContent: """
#typealias Colors {color}
#if 0 == 0
\t// ok
\t#break
#else
\t// problem
\t#throw UnexpectedException("Something is wrong, I can feel it")
#try
\tColors colors = (color.RED color.GREEN color.BLUE color.YELLOW color.MAGENTA color.CYAN color(127 127 127 0.5))
\t{integer} arr = (0 1 2 3 4 5 6)
\t#foreach &i : arr
\t\tCircle c = (50,50 100,100 color.RED)
\t\tc.paint = colors{i}
\t\ti += 1
\t\tlog["i =" i "color =" c.paint]
\tlog[arr]
""")
        XCTAssertTrue(compiler.compile())
        print(compiler.wdiuInstructions)
        let runtime = GRPHRuntime(compiler: compiler, image: GImage())
        XCTAssertTrue(runtime.run())
    }

}
