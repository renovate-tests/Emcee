import Foundation

public class TestEventPair {
    public let testStartEvent: TestStartEvent
    public let testFinishEvent: TestFinishEvent?

    public init(
        testStartEvent: TestStartEvent,
        testFinishEvent: TestFinishEvent?
        )
    {
        self.testStartEvent = testStartEvent
        self.testFinishEvent = testFinishEvent
    }
}
