import ArgLib
import Foundation

extension CommandPayload {
    
    func expectedValueHolder(
        argument: KnownArguments
    ) throws -> ArgumentValueHolder {
        return try expectedValueHolder(argumentName: argument.argumentDescription.name)
    }
    
    func optionalValueHolder(
        argument: KnownArguments
    ) throws -> ArgumentValueHolder? {
        return try optionalValueHolder(argumentName: argument.argumentDescription.name)
    }
    
    func expectedTypedValue<T: ParsableArgument>(
        argument: KnownArguments
    ) throws -> T {
        return try expectedTypedValue(argumentName: argument.argumentDescription.name)
    }
    
    func optionalTypedValue<T: ParsableArgument>(
        argument: KnownArguments
    ) throws -> T? {
        return try optionalTypedValue(argumentName: argument.argumentDescription.name)
    }
}
