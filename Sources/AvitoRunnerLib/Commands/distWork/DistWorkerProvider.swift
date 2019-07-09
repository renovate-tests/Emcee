import DistWorker
import Foundation
import Models
import ResourceLocationResolver

public protocol DistWorkerProvider {
    func createDistWorker(
        queueServerAddress: SocketAddress,
        resourceLocationResolver: ResourceLocationResolver,
        workerId: WorkerId
    ) -> DistWorker
}

public final class DefaultDistWorkerProvider: DistWorkerProvider {
    public init() {}
    
    public func createDistWorker(
        queueServerAddress: SocketAddress,
        resourceLocationResolver: ResourceLocationResolver,
        workerId: WorkerId
    ) -> DistWorker {
        return DefaultDistWorker(
            queueServerAddress: queueServerAddress,
            resourceLocationResolver: resourceLocationResolver,
            workerId: workerId
        )
    }
}
