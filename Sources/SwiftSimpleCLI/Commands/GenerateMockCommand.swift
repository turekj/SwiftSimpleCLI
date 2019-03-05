import Commandant
import Foundation
import Result
import SwiftSyntax

struct GenerateMockCommand: CommandProtocol {
    typealias Options = GenerateMockOptions

    let verb: String = "generate_mock"
    let function: String = "Creates a mock for the Mocking protocol"

    func run(_ options: Options) -> Result<(), MainError> {
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
