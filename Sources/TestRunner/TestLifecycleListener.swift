import Foundation
import Models

public protocol TestLifecycleListener: class {
    func testStarted(testEntry: TestEntry)
    func testStopped(succeeded: Bool, testEntry: TestEntry)
}

