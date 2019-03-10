import EventBus
import Foundation
import LocalHostDeterminer
import Metrics
import Models
import TestRunner

public final class RuntimeTestEventsListener: TestLifecycleListener {
    private let eventBus: EventBus
    private let testContext: TestContext

    public init(eventBus: EventBus, testContext: TestContext) {
        self.eventBus = eventBus
        self.testContext = testContext
    }

    public func testStarted(testContext: TestContext, testEntry: TestEntry) {
        eventBus.post(
            event: .runnerEvent(.testStarted(testEntry: testEntry, testContext: testContext))
        )

        MetricRecorder.capture(
            TestStartedMetric(
                host: LocalHostDeterminer.currentHostAddress,
                testClassName: testEntry.className,
                testMethodName: testEntry.methodName
            )
        )
    }

    public func testSucceeded(testContext: TestContext, testEntry: TestEntry) {
        eventBus.post(
            event: .runnerEvent(.testFinished(testEntry: testEntry, succeeded: true, testContext: testContext))
        )
    }

    public func testFailed(testContext: TestContext, testEntry: TestEntry) {
        eventBus.post(
            event: .runnerEvent(.testFinished(testEntry: testEntry, succeeded: false, testContext: testContext))
        )

        let testResult = eventPair.finishEvent?.result ?? "unknown_result"
        let testDuration = eventPair.finishEvent?.totalDuration ?? 0
        MetricRecorder.capture(
            TestFinishedMetric(
                result: testResult,
                host: eventPair.startEvent.hostName ?? "unknown_host",
                testClassName: event.testEntry.className,
                testMethodName: event.testEntry.methodName,
                testsFinishedCount: 1
            ),
            TestDurationMetric(
                result: testResult,
                host: eventPair.startEvent.hostName ?? "unknown_host",
                testClassName: event.testEntry.className,
                testMethodName: event.testEntry.methodName,
                duration: testDuration
            )
        )
    }
}

