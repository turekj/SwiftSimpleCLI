import Commandant
import Foundation

enum MainError: Error, LocalizedError {
    case fatalError(description: String)

    var errorDescription: String? {
        switch self {
        case let .fatalError(message):
            return message
        }
    }
}

let registry = CommandRegistry<MainError>()
registry.register(PrintNameCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.localizedDescription + "\n", stderr)
}
