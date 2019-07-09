import SimulatorPool
import ResourceLocationResolver
import TemporaryStuff

public final class OnDemandSimulatorPoolWithDefaultSimulatorControllerMock: OnDemandSimulatorPool<DefaultSimulatorController> {

    public var poolMethodCalled = false
    
    override public func pool(key: OnDemandSimulatorPool<DefaultSimulatorController>.Key) throws -> SimulatorPool<DefaultSimulatorController> {
        poolMethodCalled = true
        return try SimulatorPoolWithDefaultSimulatorControllerMock()
    }

    public var deleteMethodCalled = false
    
    override public func deleteSimulators() {
        deleteMethodCalled = true
    }
}
