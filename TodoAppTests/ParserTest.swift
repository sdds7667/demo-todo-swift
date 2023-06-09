//
//  ParserTest.swift
//  TodoAppTests
//
//  Created by Ion Plamadeala on 10/06/2023.
//

import XCTest
@testable import TodoApp

final class ParserTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBasics() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let command = "p'a0f,2"
        
        let expected : [Token] = [.string(value: "p"), .stringId(value: "a0f"), .string(value: ","), .number(value: 2)]
        do {
            let result = try parse(command: command)
            XCTAssertEqual(expected, result)
        } catch {
            XCTFail("The parse function should not fail here. \(error)")
        }
    }
    
    func testLoadCommand() throws {
        let command = "load project-alpha-123"
        let expected: [Token] = [.string(value: "load"), .string(value: " "), .string(value: "project"), .string(value: "-"), .string(value: "alpha"), .string(value: "-"), .number(value: 123)]
        
        do {
            let result = try parse (command: command)
            XCTAssertEqual(expected, result)
        } catch {
            XCTFail("The parser should not fail here \(error)")
        }
    }
    
    func testSpecialCharactersCommand() throws {
        let command = "#$%^&*"
        let expected: [Token] = [
            .string(value: "#"),
            .string(value: "$"),
            .string(value: "%"),
            .string(value: "^"),
            .string(value: "&"),
            .string(value: "*")
        ]
        
        do {
            let result = try parse(command: command)
            XCTAssertEqual(expected, result)
        } catch {
            XCTFail("The parser should not fail here \(error)")
        }
    }

    func testIDsWithDigits() throws {
        let command = "'abd c12 3 d e 'f45"
        let expected: [Token] = [
            .stringId(value: "abd"),
            .string(value: " "),
            .string(value: "c"),
            .number(value: 12),
            .string(value: " "),
            .number(value: 3),
            .string(value: " "),
            .string(value: "d"),
            .string(value: " "),
            .string(value: "e"),
            .string(value: " "),
            .stringId(value: "f45")
        ]
        
        do {
            let result = try parse(command: command)
            XCTAssertEqual(expected, result)
        } catch {
            XCTFail("The parser should not fail here \(error)")
        }
    }

    func testMixedIDsWithDigits() throws {
        let command = "'abc 12 3 456def"
        let expected: [Token] = [
            .stringId(value: "abc"),
            .string(value: " "),
            .number(value: 12),
            .string(value: " "),
            .number(value: 3),
            .string(value: " "),
            .number(value: 456),
            .string(value: "def")
        ]
        
        do {
            let result = try parse(command: command)
            XCTAssertEqual(expected, result)
        } catch {
            XCTFail("The parser should not fail here \(error)")
        }
    }
    
    func testIdTooSmall() {
        let cmd = "'ab"
        do {
            let result = try parse(command: cmd)
            XCTFail("Should've failed already")
        } catch {
            print("The parser did indeed fail!\(error)")
        }
        
    }
    func testBadCharacterInId() {
        let cmd = "'ab "
        do {
            let result = try parse(command: cmd)
            XCTFail("Should've failed already")
        } catch {
            print("The parser did indeed fail!\(error)")
        }
        
    }
    
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
