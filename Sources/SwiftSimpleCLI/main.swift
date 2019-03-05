import Commandant
import Foundation

enum MainError: Error {}

let registry = CommandRegistry<MainError>()

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.localizedDescription + "\n", stderr)
}
