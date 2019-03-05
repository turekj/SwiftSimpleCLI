import XCTest
@testable import SwiftSimpleCLI

final class SwiftSimpleCLITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftSimpleCLI().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
