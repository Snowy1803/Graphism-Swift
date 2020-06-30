//
//  GraphismTests.swift
//  GraphismTests
//
//  Created by Emil Pedersen on 30/06/2020.
//

import XCTest

class GraphismTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
        XCTAssertNil(SimpleType.parse(literal: "intreger"))
        XCTAssertNil(SimpleType.parse(literal: "<>float"))
        XCTAssertNil(SimpleType.parse(literal: "float{}"))
        XCTAssertNil(SimpleType.parse(literal: "<float><>"))
        XCTAssertNil(SimpleType.parse(literal: "{num}|"))
        XCTAssertNil(SimpleType.parse(literal: "|<boolean>"))
        XCTAssertNil(SimpleType.parse(literal: "<>|<boolean>"))
    }
    
    func parseType(_ literal: String, expected: String? = nil) {
        XCTAssertEqual(expected ?? literal, SimpleType.parse(literal: literal)?.string)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
