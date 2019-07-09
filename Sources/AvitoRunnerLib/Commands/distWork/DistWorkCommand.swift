import ArgLib
import DistWorker
import Foundation
import Logging
import LoggingSetup
import Models
import ResourceLocationResolver

public final class DistWorkCommand: Command {
    public let name = "distWork"
    public let description = "Takes jobs from a dist runner queue and performs them"
    public var arguments: Arguments = [
        KnownArguments.analyticsConfiguration.argumentDescription,
        KnownArguments.queueServer.argumentDescription,
        KnownArguments.workerId.argumentDescription
    ]
    
    private let distWorkerProvider: DistWorkerProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        distWorkerProvider: DistWorkerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.distWorkerProvider = distWorkerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run(payload: CommandPayload) throws {
        let analyticsConfigurationLocation = AnalyticsConfigurationLocation(
            try payload.optionalTypedValue(argument: .analyticsConfiguration)
        )
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try setupAnalytics(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        
        let queueServerAddress: SocketAddress = try payload.expectedTypedValue(argument: .queueServer)
        let workerId = WorkerId(
            value: try payload.expectedTypedValue(argument: .workerId)
        )
        
        let distWorker = distWorkerProvider.createDistWorker(
            queueServerAddress: queueServerAddress,
            resourceLocationResolver: resourceLocationResolver,
            workerId: workerId
        )
        try distWorker.start()
    }
    
    private func setupAnalytics(
        analyticsConfigurationLocation: AnalyticsConfigurationLocation
    ) throws {
        let analyticsConfigurator = AnalyticsConfigurator(
            resourceLocationResolver: resourceLocationResolver
        )
        try analyticsConfigurator.setup(
            analyticsConfigurationLocation: analyticsConfigurationLocation
        )
    }
}
