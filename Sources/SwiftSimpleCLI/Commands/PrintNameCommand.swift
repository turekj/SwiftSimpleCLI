import Commandant
import Foundation
import Result
import SwiftSyntax

struct PrintNameCommand: CommandProtocol {
    typealias Options = PrintNameOptions

    let verb: String = "print_name"
    let function: String = "Prints names of types declared in the file"

    func run(_ options: Options) -> Result<(), MainError> {
        guard let url = URL(string: options.path), let parser = try? SyntaxTreeParser.parse(url) else {
            return Result(error: .fatalError(description: "Could not parse Swift file at \(options.path) path"))
        }

        let visitor = TokenVisitor()
        visitor.visit(parser)

        return Result(value: ())
    }
}

struct PrintNameOptions: OptionsProtocol {
    let path: String

    static func create(_ path: String) -> PrintNameOptions {
        return PrintNameOptions(path: path)
    }

    static func evaluate(_ m: CommandMode) -> Result<PrintNameOptions, CommandantError<MainError>> {
        return create
            <*> m <| Argument(usage: "the swift file to read")
    }
}

class TokenVisitor: SyntaxVisitor {

    private var nextIdentifierType: String?

    override func visit(_ token: TokenSyntax) {
        switch token.tokenKind {
        case .classKeyword, .extensionKeyword, .protocolKeyword:
            nextIdentifierType = token.text
        case let .identifier(identifier):
            if let identifierType = nextIdentifierType {
                nextIdentifierType = nil
                print("\(identifierType) \(identifier)")
            }
        default:
            break
        }
    }

}
