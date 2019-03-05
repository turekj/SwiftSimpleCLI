import XCTest

import SwiftSimpleCLITests

var tests = [XCTestCaseEntry]()
tests += SwiftSimpleCLITests.allTests()
XCTMain(tests)