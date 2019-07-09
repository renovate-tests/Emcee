import ArgLib
import Foundation
import XCTest

final class CommandPayloadTests: XCTestCase {
    func test___extracting_argument_values() throws {
        let valueHolders = Set(
            [
                ArgumentValueHolder(argumentName: "string", stringValue: "hello"),
                ArgumentValueHolder(argumentName: "int", stringValue: "42")
            ]
        )
        let payload = CommandPayload(valueHolders: valueHolders)
        
        XCTAssertEqual(
            try payload.expectedTypedValue(argumentName: "int"),
            42
        )
        XCTAssertEqual(
            try payload.expectedTypedValue(argumentName: "string"),
            "hello"
        )
    }
    
    func test___throws_on_unexpected_argument_value_request() throws {
        let payload = CommandPayload(valueHolders: Set<ArgumentValueHolder>())
        
        XCTAssertThrowsError(
            try payload.expectedTypedValue(argumentName: "argname") as String
        )
    }
}

