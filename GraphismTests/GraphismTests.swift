//
//  GraphismTests.swift
//  GraphismTests
//
//  Created by Emil Pedersen on 30/06/2020.
//

import XCTest

class GraphismTests: XCTestCase {
    
    var context: GRPHContext!
    var compiler: GRPHCompiler!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        compiler = GRPHCompiler(entireContent: "")
        context = GRPHContext(parser: compiler)
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
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "intreger"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<>float"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "float{}"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<float><>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "{num}|"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "|<boolean>"))
        XCTAssertNil(GRPHTypes.parse(context: context, literal: "<>|<boolean>"))
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
        
        XCTAssertEqual(compiler.internStrings.debugDescription, #"["\"hello world", "\"another str", "\"he\"llo\" w\"o\"rld", "\"first ", "\"second"]"#)
    }
    
    func testExpressionParsing() throws {
        compiler.globalVariables.append(Variable(name: "var", type: SimpleType.integer, final: false, compileTime: true))
        
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
        XCTAssertEqual(try Expressions.parse(context: context, infer: SimpleType.float, literal: "32 == 42 || 67 == 69 || [96 != 420 && 2 > 1]").string, "[[32 == 42] || [67 == 69]] || [[96 != 420] && [2 > 1]]")
        
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
    
    func testSampleProgram() {
        compiler = GRPHCompiler(entireContent: """
#if 0 == 0
\t// ok
\t#break
#else
\t// problem
\t#break
#try
\t// {integer} arr = <integer>{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
\t {integer} arr = (0 1 2 3 4 5 6 7 8 9)
\t#foreach &i : arr
\t\tCircle c = (50,50 100,100 color.RED)
""")
        _ = compiler.compile()
        print(compiler.wdiuInstructions)
    }
    
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
