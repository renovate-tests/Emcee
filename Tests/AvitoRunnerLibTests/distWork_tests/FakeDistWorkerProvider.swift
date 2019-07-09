import AvitoRunnerLib
import DistWorker
import Foundation
import Models
import ResourceLocationResolver

public final class FakeDistWorkerProvider: DistWorkerProvider {
    public var allCreatedDistWorkers = [FakeDistWorker]()
    
    public init() {}
    
    public func createDistWorker(
        queueServerAddress: SocketAddress,
        resourceLocationResolver: ResourceLocationResolver,
        workerId: WorkerId
    ) -> DistWorker {
        let worker = FakeDistWorker(
            queueServerAddress: queueServerAddress,
            resourceLocationResolver: resourceLocationResolver,
            workerId: workerId
        )
        allCreatedDistWorkers.append(worker)
        return worker
    }
}
