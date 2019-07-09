import Models
import RuntimeDump

public final class RuntimeTestQuerierMock: RuntimeTestQuerier {
    public var numberOfCalls = 0
    public var configuration: RuntimeDumpConfiguration?
    public var result = RuntimeQueryResult(
        unavailableTestsToRun: [],
        availableRuntimeTests: []
    )
    
    public func queryRuntime(configuration: RuntimeDumpConfiguration) throws -> RuntimeQueryResult {
        numberOfCalls += 1
        self.configuration = configuration
        return result
    }
}
