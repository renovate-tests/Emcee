import Foundation
import Models

public final class TestStartEvent {
    public let testEntry: TestEntry
    public let timestamp: Date

    public init(
        testEntry: TestEntry,
        timestamp: Date
        )
    {
        self.testEntry = testEntry
        self.timestamp = timestamp
    }
}
