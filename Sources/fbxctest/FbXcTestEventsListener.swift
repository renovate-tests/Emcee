import Dispatch
import Foundation
import Logging

final class FbXcTestEventsListener {    
    private let pairsController = TestEventPairsController()
    
    private let onTestStarted: ((FbXcTestStartedEvent) -> ())
    private let onTestStopped: ((FbXcTestEventPair) -> ())

    public init(
        onTestStarted: @escaping ((FbXcTestStartedEvent) -> ()),
        onTestStopped: @escaping ((FbXcTestEventPair) -> ())
        )
    {
        self.onTestStarted = onTestStarted
        self.onTestStopped = onTestStopped
    }
    
    func testStarted(_ event: FbXcTestStartedEvent) {
        pairsController.append(
            FbXcTestEventPair(startEvent: event, finishEvent: nil)
        )
        onTestStarted(event)
    }
    
    func testFinished(_ event: FbXcTestFinishedEvent) {
        guard let pair = pairsController.popLast() else {
            Logger.warning("Unable to find matching start event for \(event)")
            Logger.warning("The result for test \(event.testName) (\(event.result) will be lost.")
            return
        }
        guard pair.startEvent.test == event.test else {
            Logger.warning("Last TestStartedEvent \(pair.startEvent) does not match just received finished event \(event)")
            Logger.warning("The result for test \(event.testName) (\(event.result) will be lost.")
            return
        }
        let newPair = FbXcTestEventPair(startEvent: pair.startEvent, finishEvent: event)
        pairsController.append(newPair)
        onTestStopped(newPair)
    }
    
    func testPlanFinished(_ event: FbXcTestPlanFinishedEvent) {
        guard let pair = self.lastStartedButNotFinishedTestEventPair else {
            Logger.debug("Test plan finished, and there is no hang test found. All started tests have corresponding finished events.")
            return
        }
        reportTestPlanFinishedWithHangStartedTest(
            startEvent: pair.startEvent,
            testPlanFailed: !event.succeeded,
            testPlanEventTimestamp: event.timestamp
        )
    }
    
    func testPlanError(_ event: FbXcTestPlanErrorEvent) {
        guard let pair = self.lastStartedButNotFinishedTestEventPair else {
            Logger.warning("Test plan errored, but there is no hang test found. All started tests have corresponding finished events.")
            return
        }
        reportTestPlanFinishedWithHangStartedTest(
            startEvent: pair.startEvent,
            testPlanFailed: true,
            testPlanEventTimestamp: event.timestamp
        )
    }
    
    // MARK: - Other methods that call basic methods above
    
    func errorDuringTest(_ event: FbXcGenericErrorEvent) {
        if event.domain == "com.facebook.XCTestBootstrap" {
            processBootstrapError(event)
        }
    }
    
    func longRunningTest() {
        guard let startEvent = lastStartedButNotFinishedTestEventPair?.startEvent else { return }
        let timestamp = Date().timeIntervalSince1970
        let failureEvent = FbXcTestFinishedEvent(
            test: startEvent.test,
            result: "long running test",
            className: startEvent.testClassName,
            methodName: startEvent.testMethodName,
            totalDuration: timestamp - startEvent.timestamp,
            exceptions: [FbXcTestExceptionEvent(reason: "Test timeout. Test did not finish in time.", filePathInProject: #file, lineNumber: #line)],
            succeeded: false,
            output: "",
            logs: [],
            timestamp: timestamp)
        testFinished(failureEvent)
    }
    
    func timeoutDueToSilence() {
        guard let startEvent = lastStartedButNotFinishedTestEventPair?.startEvent else { return }
        let timestamp = Date().timeIntervalSince1970
        let failureEvent = FbXcTestFinishedEvent(
            test: startEvent.test,
            result: "timeout due to silence",
            className: startEvent.testClassName,
            methodName: startEvent.testMethodName,
            totalDuration: timestamp - startEvent.timestamp,
            exceptions: [FbXcTestExceptionEvent(reason: "Timeout due to silence", filePathInProject: #file, lineNumber: #line)],
            succeeded: false,
            output: "",
            logs: [],
            timestamp: timestamp)
        testFinished(failureEvent)
    }
    
    var allEventPairs: [FbXcTestEventPair] {
        return pairsController.allPairs
    }
    
    var lastStartedButNotFinishedTestEventPair: FbXcTestEventPair? {
        if let pair = pairsController.lastPair, pair.finishEvent == nil {
            return pair
        }
        return nil
    }
    
    // MARK: - Private
    
    private func processBootstrapError(_ event: FbXcGenericErrorEvent) {
        guard let startEvent = lastStartedButNotFinishedTestEventPair?.startEvent else { return }
        let timestamp = Date().timeIntervalSince1970
        let bootstrapFailureEvent = FbXcTestFinishedEvent(
            test: startEvent.test,
            result: "bootstrap error",
            className: startEvent.testClassName,
            methodName: startEvent.testMethodName,
            totalDuration: timestamp - startEvent.timestamp,
            exceptions: [FbXcTestExceptionEvent(reason: "Failed to bootstap event: \(event.text ?? "no details")", filePathInProject: #file, lineNumber: #line)],
            succeeded: false,
            output: "",
            logs: [],
            timestamp: timestamp)
        testFinished(bootstrapFailureEvent)
    }
    
    private func reportTestPlanFinishedWithHangStartedTest(
        startEvent: FbXcTestStartedEvent,
        testPlanFailed: Bool,
        testPlanEventTimestamp: TimeInterval)
    {
        let finishEvent = FbXcTestFinishedEvent(
            test: startEvent.test,
            result: "test plan early finish",
            className: startEvent.testClassName,
            methodName: startEvent.testMethodName,
            totalDuration: testPlanEventTimestamp - startEvent.timestamp,
            exceptions: [
                FbXcTestExceptionEvent(
                    reason: "test plan finished (\(testPlanFailed ? "failed" : "with success")) but test did not receive finish event",
                    filePathInProject: #file,
                    lineNumber: #line)
            ],
            succeeded: false,
            output: "",
            logs: [],
            timestamp: testPlanEventTimestamp)
        Logger.warning("Test plan finished, but hang test found: \(startEvent.description). Adding a finished event for it: \(finishEvent.description)")
        testFinished(finishEvent)
    }
}
