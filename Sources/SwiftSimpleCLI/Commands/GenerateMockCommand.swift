import Commandant
import Foundation
import Result
import SwiftSyntax
import PathKit

struct GenerateMockCommand: CommandProtocol {
    typealias Options = GenerateMockOptions

    let verb: String = "generate_mock"
    let function: String = "Creates a mock for the Mocking protocol"

    func run(_ options: Options) -> Result<(), MainError> {
        guard let url = URL(string: options.inputPath), let parser = try? SyntaxTreeParser.parse(url) else {
            return Result(error: .fatalError(description: "Could not parse Swift file at \(options.inputPath) path"))
        }

        let visitor = GenerateMockTokenVisitor()
        visitor.visit(parser)

        var protocolParser = ProtocolParser(index: 0, tokens: visitor.tokens)

        do {
            let parsed = try protocolParser.parse()
            let generator = MockGenerator()

            for each in generator.generateMock(for: parsed) {
                print(each)
            }
            try Path(options.outputPath).write(Data("Hello world".utf8))
        } catch let error {
            print(error)
            return Result(error: .fatalError(description: "Could not write output to \(options.outputPath) file"))
        }

        return Result(value: ())
    }
}

struct GenerateMockOptions: OptionsProtocol {
    let inputPath: String
    let outputPath: String

    static func create(_ inputPath: String) -> (String) -> GenerateMockOptions {
        return { outputPath in
            GenerateMockOptions(inputPath: inputPath, outputPath: outputPath)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<GenerateMockOptions, CommandantError<MainError>> {
        return create
            <*> m <| Argument(usage: "the swift file to mock")
            <*> m <| Argument(usage: "the output file path")
    }
}

class GenerateMockTokenVisitor: SyntaxVisitor {

    var tokens: [TokenKind] = []

    override func visit(_ token: TokenSyntax) {
        switch token.tokenKind {
        case .protocolKeyword,
             .colon,
             .leftBrace,
             .rightBrace,
             .leftParen,
             .rightParen,
             .funcKeyword,
             .comma,
             .arrow,
             .identifier:
            tokens.append(token.tokenKind)
        default:
            break
        }
    }

}

enum ParsingError: Error {
    case invalid
}

struct ProtocolParser {

    var index: Int = 0
    let tokens: [TokenKind]

    mutating func pop() -> TokenKind {
        defer { index += 1 }
        return tokens[index]
    }

    func peek() -> TokenKind {
        return tokens[index]
    }

    var hasTokens: Bool {
        return index < tokens.count
    }

    mutating func parse() throws -> [ProtocolExpression] {
        var protocols: [ProtocolExpression] = []

        while hasTokens {
            if let `protocol` = try? parseProtocol() {
                protocols.append(`protocol`)
            }
        }

        return protocols
    }

    mutating func parseProtocol() throws -> ProtocolExpression {
        guard case .protocolKeyword = pop() else {
            throw ParsingError.invalid
        }

        let name = try parseIdentifier()
        var conformances: [String] = []

        if case .colon = peek() {
            conformances = try parseProtocolConformances()
        }

        guard case .leftBrace = pop() else {
            throw ParsingError.invalid
        }

        var functions: [FunctionExpression] = []

        functionsLoop: while true {
            switch peek() {
            case .funcKeyword:
                functions.append(try parseFunction())
            case .rightBrace:
                break functionsLoop
            default:
                throw ParsingError.invalid
            }
        }

        guard case .rightBrace = pop() else {
            throw ParsingError.invalid
        }

        return ProtocolExpression(name: name, functions: functions, conformances: conformances)
    }

    mutating func parseProtocolConformances() throws -> [String] {
        guard case .colon = pop() else {
            throw ParsingError.invalid
        }

        var conformances: [String] = []

        conformancesLoop: while true {
            switch peek() {
            case .comma:
                _ = pop()
            case .identifier:
                conformances.append(try parseIdentifier())
            case .leftBrace:
                break conformancesLoop
            default:
                throw ParsingError.invalid
            }
        }

        return conformances
    }

    mutating func parseFunction() throws -> FunctionExpression {
        guard case .funcKeyword = pop() else {
            throw ParsingError.invalid
        }

        let name = try parseIdentifier()

        guard case .leftParen = pop() else {
            throw ParsingError.invalid
        }

        var arguments: [ArgumentExpression] = []

        argumentsLoop: while true {
            switch peek() {
            case .comma:
                _ = pop()
            case .identifier:
                arguments.append(try parseArgument())
            case .rightParen:
                break argumentsLoop
            default:
                throw ParsingError.invalid
            }
        }

        guard case .rightParen = pop() else {
            throw ParsingError.invalid
        }

        var returnType = "Void"

        if case .arrow = peek() {
            _ = pop()
            returnType = try parseType()
        }

        return FunctionExpression(name: name, arguments: arguments, returnType: returnType)
    }

    mutating func parseArgument() throws -> ArgumentExpression {
        let name = try parseIdentifier()

        guard case .colon = pop() else {
            throw ParsingError.invalid
        }

        let type = try parseType()

        return ArgumentExpression(name: name, type: type)
    }

    mutating func parseIdentifier() throws -> String {
        guard case let .identifier(identifier) = pop() else {
            throw ParsingError.invalid
        }

        return identifier
    }

    mutating func parseType() throws -> String {
        return try parseIdentifier()
    }
}

struct Token {
    let type: TokenKind
    let identifier: String?
}

struct ProtocolExpression {
    let name: String
    let functions: [FunctionExpression]
    let conformances: [String]
}

struct FunctionExpression {
    let name: String
    let arguments: [ArgumentExpression]
    let returnType: String
}

struct ArgumentExpression {
    let name: String
    let type: String
}

class MockGenerator {

    func generateMock(for protocols: [ProtocolExpression]) -> [DeclSyntax] {
        return protocols.filter { $0.conformances.contains("Mocking") }.map(generateMock)
    }

    private func generateMock(for proto: ProtocolExpression) -> DeclSyntax {
        let classKeyword = SyntaxFactory.makeClassKeyword(trailingTrivia: .spaces(1))
        let className = SyntaxFactory.makeIdentifier(proto.name + "Mock", trailingTrivia: .spaces(1))

        let classMembers = MemberDeclBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(2)))
            proto.functions.forEach { builder.addDecl($0.propertyCallSyntax) }
            proto.functions.forEach { builder.addDecl($0.functionSyntax) }
            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1), trailingTrivia: .newlines(1)))
        }

        return ClassDeclSyntax { builder in
            builder.useClassKeyword(classKeyword)
            builder.useIdentifier(className)
            builder.useMembers(classMembers)
        }
    }

}

extension ArgumentExpression {

    func syntax(isLast: Bool) -> FunctionParameterSyntax {
        return FunctionParameterSyntax { builder in
            builder.useFirstName(SyntaxFactory.makeIdentifier(name))
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
            builder.useType(SyntaxFactory.makeTypeIdentifier(type))
            if !isLast {
                builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
            }
        }
    }

}

extension FunctionExpression {

    var propertyCallSyntax: VariableDeclSyntax {
        var propertyType = ""

        if let argument = arguments.first, arguments.count == 1 {
            propertyType = argument.type
        } else {
            propertyType = "(" + arguments.map { argument in
                "\(argument.name): \(argument.type)"
            }.joined(separator: ", ") + ")"
        }

        let tokens = SyntaxFactory.makeTokenList([
            SyntaxFactory.makeLeftParenToken(),
            SyntaxFactory.makeIdentifier("set"),
            SyntaxFactory.makeRightParenToken(trailingTrivia: .spaces(1))
        ])

        let modifiers = SyntaxFactory.makeDeclModifier(
            name: SyntaxFactory.makePrivateKeyword(leadingTrivia: .spaces(4)),
            detail: tokens
        )

        let identifier = SyntaxFactory.makeIdentifierPattern(
            identifier: SyntaxFactory.makeIdentifier(name + "Invoked", leadingTrivia: .spaces(1))
        )

        let type = SyntaxFactory.makeTypeAnnotation(
            colon: SyntaxFactory.makeColonToken(),
            type: SyntaxFactory.makeTypeIdentifier("\(propertyType)?", leadingTrivia: .spaces(1), trailingTrivia: .newlines(1))
        )

        let patternBinding = SyntaxFactory.makePatternBinding(
            pattern: identifier,
            typeAnnotation: type,
            initializer: nil,
            accessor: nil,
            trailingComma: nil
        )

        return SyntaxFactory.makeVariableDecl(
            attributes: nil,
            modifiers: SyntaxFactory.makeModifierList([modifiers]),
            letOrVarKeyword: SyntaxFactory.makeVarKeyword(),
            bindings: SyntaxFactory.makePatternBindingList([patternBinding])
        )
    }

    var functionSyntax: FunctionDeclSyntax {
        let inputSyntax = ParameterClauseSyntax { builder in
            builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
            builder.useRightParen(SyntaxFactory.makeRightParenToken(trailingTrivia: .spaces(1)))
            arguments.enumerated().forEach { offset, argument in
                builder.addFunctionParameter(argument.syntax(isLast: offset == arguments.count - 1))
            }
        }

        let signature = FunctionSignatureSyntax { builder in
            builder.useInput(inputSyntax)
        }

        var functionCallArguments = ""

        if let argument = arguments.first, arguments.count == 1 {
            functionCallArguments = argument.name
        } else {
            functionCallArguments = "(" + arguments.map { "\($0.name): \($0.name)" }.joined(separator: ", ") + ")"
        }

        let functionCallBlock = "\(name)Invoked = \(functionCallArguments)"

        let blockItem = CodeBlockItemSyntax { builder in
            builder.useItem(SyntaxFactory.makeUnknown(functionCallBlock, leadingTrivia: .spaces(8), trailingTrivia: .newlines(1)))
        }

        let codeBlock = CodeBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))
            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .spaces(4), trailingTrivia: .newlines(1)))
            builder.addCodeBlockItem(blockItem)
        }

        let functionDeclaration = FunctionDeclSyntax { builder in
            builder.useFuncKeyword(SyntaxFactory.makeFuncKeyword(leadingTrivia: [.newlines(1), .spaces(4)], trailingTrivia: .spaces(1)))
            builder.useIdentifier(SyntaxFactory.makeIdentifier(name))
            builder.useBody(codeBlock)
            builder.useSignature(signature)
        }

        return functionDeclaration
    }

}
