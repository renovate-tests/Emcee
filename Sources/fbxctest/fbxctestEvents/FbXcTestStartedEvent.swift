import Foundation

public final class FbXcTestStartedEvent: CustomStringConvertible, CommonTestFields, Codable {
    public let event: FbXcTestEventName = .testStarted
    public let test: String          // e.g. -[FunctionalTests.MainPageTest test_dataSet0]
    private let className: String     // e.g. FunctionalTests.MainPageTest
    private let methodName: String    // test_dataSet0
    public let timestamp: TimeInterval
    public let simulatorId: String?
    
    public init(
        test: String,
        className: String,
        methodName: String,
        timestamp: TimeInterval,
        hostName: String? = nil,
        simulatorId: String? = nil
        )
    {
        self.test = test
        self.className = className
        self.methodName = methodName
        self.timestamp = timestamp
        self.simulatorId = simulatorId
    }

    public func withSimulatorId(newSimulatorId: String) -> FbXcTestStartedEvent {
        return FbXcTestStartedEvent(
            test: test,
            className: className,
            methodName: methodName,
            timestamp: timestamp,
            simulatorId: newSimulatorId
        )
    }
    
    public var testClassName: String {
        return FbXcTestEventClassNameParser.className(moduledClassName: className)
    }
    
    public var testMethodName: String {
        return methodName
    }
    
    public var testModuleName: String {
        return FbXcTestEventClassNameParser.moduleName(moduledClassName: className)
    }
    
    public var description: String {
        return "Started test \(testName)"
    }
}
