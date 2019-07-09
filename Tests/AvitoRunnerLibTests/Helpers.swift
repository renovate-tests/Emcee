import AvitoRunnerLib
import ArgLib
import Foundation
import Models

func argumentValue(
    _ argument: KnownArguments,
    value: String
    ) -> ArgumentValueHolder {
    return ArgumentValueHolder(
        argumentName: argument.argumentDescription.name,
        stringValue: value
    )
}
