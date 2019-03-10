import Foundation
import Models

public final class TestFinishEvent {
    public let testEntry: TestEntry
    public let result: String
    public let succeeded: Bool
    public let timestamp: Date
    public let exceptions: [TestException]

    public init(
        testEntry: TestEntry,
        result: String,
        succeeded: Bool,
        timestamp: Date,
        exceptions: [TestException]
        )
    {
        self.testEntry = testEntry
        self.result = result
        self.succeeded = succeeded
        self.timestamp = timestamp
        self.exceptions = exceptions
    }
}
