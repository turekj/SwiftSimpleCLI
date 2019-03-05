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

        print(visitor.parsedProtocols)

        do {
            try Path(options.outputPath).write(Data("Hello world".utf8))
        } catch {
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

    private var protocolOpened: Bool = false
    private var protocolName: String?
    private var protocolColon: Bool = false
    private var isMocking: Bool = false
    private var functionOpened: Bool = false
    private var functionName: String?
    private var argumentOpened: Bool = false
    private var argumentTypeOpened: Bool = false
    private var argumentName: String?
    private var argumentType: String?

    var parsedProtocols: [ProtocolDescriptor] = []
    var parsedFunctions: [FunctionDescriptor] = []
    var parsedArguments: [ArgumentDescriptor] = []

    override func visit(_ token: TokenSyntax) {
        switch token.tokenKind {
        case .protocolKeyword:
            protocolOpened = true
            protocolName = nil
            parsedFunctions = []
        case let .identifier(identifier):
            if protocolOpened && protocolName == nil {
                protocolName = identifier
            } else if protocolColon {
                isMocking = isMocking || identifier == "Mocking"
            } else if functionOpened && functionName == nil {
                functionName = identifier
            } else if argumentOpened && argumentName == nil && !argumentTypeOpened {
                argumentName = identifier
            } else if argumentTypeOpened {
                argumentType = identifier
            }
        case .colon:
            if protocolOpened && !argumentOpened {
                protocolColon = true
            } else if argumentOpened {
                argumentTypeOpened = true
            }
        case .leftBrace:
            protocolColon = false
        case .rightBrace:
            if let protocolName = protocolName, isMocking {
                self.protocolName = nil
                protocolOpened = false
                protocolColon = false
                isMocking = false
                parsedProtocols.append(ProtocolDescriptor(name: protocolName, functions: parsedFunctions))
                parsedFunctions = []
            }
        case .funcKeyword:
            functionOpened = true
            functionName = nil
        case .leftParen:
            if functionOpened {
                argumentOpened = true
                argumentTypeOpened = false
            }
        case .rightParen:
            if let functionName = functionName, functionOpened {
                if let argumentName = argumentName, let argumentType = argumentType, argumentOpened {
                    self.argumentName = nil
                    argumentOpened = false
                    argumentTypeOpened = false
                    parsedArguments.append(ArgumentDescriptor(name: argumentName, type: argumentType))
                }

                self.functionName = nil
                functionOpened = false
                parsedFunctions.append(FunctionDescriptor(name: functionName, arguments: parsedArguments))
                parsedArguments = []
            }
        case .comma:
            if let argumentName = argumentName, let argumentType = argumentType, argumentOpened {
                self.argumentName = nil
                argumentTypeOpened = false
                parsedArguments.append(ArgumentDescriptor(name: argumentName, type: argumentType))
            }
        default:
            break
        }
    }

}

struct ProtocolDescriptor {
    let name: String
    let functions: [FunctionDescriptor]
}

struct FunctionDescriptor {
    let name: String
    let arguments: [ArgumentDescriptor]
}

struct ArgumentDescriptor {
    let name: String
    let type: String
}
