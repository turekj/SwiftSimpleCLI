import Commandant
import Result

struct PrintNameCommand: CommandProtocol {
    typealias Options = PrintNameOptions

    let verb: String = "print_name"
    let function: String = "Prints names of types declared in the file"

    func run(_ options: Options) -> Result<(), MainError> {
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
