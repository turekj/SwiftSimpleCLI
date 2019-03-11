import Commandant
import Foundation
import SwiftSimpleCLIFramework

let registry = CommandRegistry<MainError>()
registry.register(PrintNameCommand())
registry.register(GenerateMockCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.localizedDescription + "\n", stderr)
}
