import ArgLib
import Foundation

final class CommandA: Command {
    let name: String = "command_a"
    let description: String = ""
    let arguments = Arguments([])
    
    func run(valueHolders: Set<ArgumentValueHolder>) throws {}
}

final class CommandB: Command {
    let name: String = "command_b"
    let description: String = ""
    let arguments = Arguments(
        [
            ArgumentDescription(name: "string", overview: "string"),
            ArgumentDescription(name: "int", overview: "int")
        ]
    )
    
    func run(valueHolders: Set<ArgumentValueHolder>) throws {}
}
