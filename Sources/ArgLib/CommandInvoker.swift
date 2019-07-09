import Foundation

public final class CommandInvoker {
    private let commands: [Command]
    
    public init(commands: [Command]) {
        self.commands = commands
    }
    
    public func invokeSuitableCommand(
        arguments: [String] = CommandLine.meaningfulArguments,
        whenDeterminedCommandToRun: (Command) -> () = { _ in }
    ) throws {
        let command = try CommandParser.choose(
            commandFrom: commands,
            stringValues: arguments
        )
        
        whenDeterminedCommandToRun(command)
        
        let valueHolders = try CommandParser.map(
            stringValues: Array(arguments.dropFirst()),
            to: command.arguments.argumentDescriptions
        )
        
        try command.run(
            payload: CommandPayload(
                valueHolders: valueHolders
            )
        )
    }
}
