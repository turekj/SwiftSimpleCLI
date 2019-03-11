import XCTest
import PathKit
import SwiftSyntax
import class Foundation.Bundle
@testable import SwiftSimpleCLIFramework

private extension ProtocolExpression {

    static var helloWorld: ProtocolExpression {
        let functions: [FunctionExpression] = [
            .init(name: "greet", arguments: [ArgumentExpression(name: "person", type: "String")], returnType: "String"),
            .init(name: "bye", arguments: [ArgumentExpression(name: "person", type: "String")], returnType: "String")
        ]

        return ProtocolExpression(name: "HelloWorld", functions: functions, conformances: ["AnyConformance", "Mocking"])
    }

    static var nonMockableProtocol: ProtocolExpression {
        let functions: [FunctionExpression] = [
            .init(name: "nonMockableGreet", arguments: [ArgumentExpression(name: "person", type: "String")], returnType: "String")
        ]

        return ProtocolExpression(name: "NonMockableProtocol", functions: functions, conformances: [])
    }

    static var buyAnimating: ProtocolExpression {
        let arguments: [ArgumentExpression] = [
            .init(name: "view", type: "UIView"),
            .init(name: "detailsView", type: "VinylDetailsView"),
            .init(name: "barView", type: "ShoppingBarView")
        ]

        let function = FunctionExpression(name: "animateBuy", arguments: arguments, returnType: "Void")

        return ProtocolExpression(name: "BuyAnimating", functions: [function], conformances: ["Mocking"])
    }

}

final class ProtocolParserTests: XCTestCase {
    func testProtocolParser() throws {
        let path = Path("/Users/kuba/dev/elp/projects/SwiftSimpleCLI/Resources/BuyAnimating.swift")
        let syntaxTreeParser = try SyntaxTreeParser.parse(path.url)
        let visitor = GenerateMockTokenVisitor()
        visitor.visit(syntaxTreeParser)

        var sut = ProtocolParser(index: 0, tokens: visitor.tokens)
        let parsed = try sut.parse()

        XCTAssertEqual(3, parsed.count)
        XCTAssertEqual(ProtocolExpression.helloWorld, parsed[0])
        XCTAssertEqual(ProtocolExpression.nonMockableProtocol, parsed[1])
        XCTAssertEqual(ProtocolExpression.buyAnimating, parsed[2])
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }

    static var allTests = [
        ("testProtocolParser", testProtocolParser),
    ]
}
