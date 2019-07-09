import DistWorker
import Foundation
import Models
import ResourceLocationResolver

public final class FakeDistWorker: DistWorker {
    public let queueServerAddress: SocketAddress
    public let resourceLocationResolver: ResourceLocationResolver
    public let workerId: WorkerId

    public init(
        queueServerAddress: SocketAddress,
        resourceLocationResolver: ResourceLocationResolver,
        workerId: WorkerId
    ) {
        self.queueServerAddress = queueServerAddress
        self.resourceLocationResolver = resourceLocationResolver
        self.workerId = workerId
    }
    
    public var calledStart = false
    
    public func start() throws {
        calledStart = true
    }
}
