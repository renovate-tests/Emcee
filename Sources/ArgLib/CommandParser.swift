import Foundation
import OrderedSet

public enum CommandParserError: Error, CustomStringConvertible {
    case expectedValueAfterDashedArgument(ArgumentDescription)
    case missingValue(ArgumentDescription)
    case unexpectedValues([String])
    case noCommandProvided
    case unknownCommand(name: String)

    public var description: String {
        switch self {
        case .expectedValueAfterDashedArgument(let description):
            return "Missing argument: \(description.name.expectedInputValue)"
        case .missingValue(let description):
            return "Expected to have a value next to '\(description.name.expectedInputValue)'"
        case .unexpectedValues(let values):
            return "Unexpected or unmatched values: \(values)"
        case .noCommandProvided:
            return "No command provided."
        case .unknownCommand(let name):
            return "Unrecognized command: \(name)"
        }
    }
}

public final class CommandParser {
    
    public static func choose(
        commandFrom commands: [Command],
        stringValues: [String] = CommandLine.meaningfulArguments
    ) throws -> Command {
        guard let commandName = stringValues.first else {
            throw CommandParserError.noCommandProvided
        }
        guard let command = commands.first(where: { $0.name == commandName }) else {
            throw CommandParserError.unknownCommand(name: commandName)
        }
        return command
    }
    
    public static func map(
        stringValues: [String],
        to commandArguments: OrderedSet<ArgumentDescription>
    ) throws -> Set<ArgumentValueHolder> {
        var stringValues = stringValues
        
        let result = try commandArguments.map { argumentDescription -> ArgumentValueHolder in
            guard let index = stringValues.firstIndex(of: argumentDescription.name.expectedInputValue) else {
                throw CommandParserError.expectedValueAfterDashedArgument(argumentDescription)
            }
            
            guard index + 1 < stringValues.count else {
                throw CommandParserError.missingValue(argumentDescription)
            }
            
            let stringValue = stringValues.remove(at: index + 1)
            stringValues.remove(at: index)
            
            return ArgumentValueHolder(
                argumentName: argumentDescription.name,
                stringValue: stringValue
            )
        }
        
        if !stringValues.isEmpty {
            throw CommandParserError.unexpectedValues(stringValues)
        }
        
        return Set(result)
    }
}
