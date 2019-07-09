import ArgLib
import EventBus
import Extensions
import Foundation
import LocalQueueServerRunner
import Logging
import LoggingSetup
import Models
import PluginManager
import RuntimeDump
import SimulatorPool
import PortDeterminer
import TemporaryStuff
import ResourceLocationResolver
import Version
import OrderedSet

public final class StartQueueServerCommand: BaseCommand {
    public override var name: String { return "startLocalQueueServer" }
    public override var description: String { return "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API" }
    public override var specificArguments: [ArgumentDescription] {
        return [
            KnownArguments.queueServerRunConfigurationLocation.argumentDescription
        ]
    }

    public override func run(
        payload: CommandPayload,
        eventBus: EventBus,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        runtimeTestQuerier: RuntimeTestQuerier,
        temporaryFolder: TemporaryFolder
    ) throws {
        let queueServerRunConfiguration = try loadQueueServerRunConfiguration(
            location: QueueServerRunConfigurationLocation(
                try payload.expectedTypedValue(argument: .queueServerRunConfigurationLocation)
            )
        )
        
        try LoggingSetup.setupAnalytics(analyticsConfiguration: queueServerRunConfiguration.analyticsConfiguration)
        try startQueueServer(queueServerRunConfiguration: queueServerRunConfiguration)
    }
    
    private func loadQueueServerRunConfiguration(
        location: QueueServerRunConfigurationLocation
    ) throws -> QueueServerRunConfiguration {
        let resolvingResult = try resourceLocationResolver.resolvePath(resourceLocation: location.resourceLocation)
        let data = try Data(contentsOf: URL(fileURLWithPath: try resolvingResult.directlyAccessibleResourcePath()))
        return try ArgumentsReader.decoderWithSnakeCaseSupport.decode(QueueServerRunConfiguration.self, from: data)
    }
    
    private func startQueueServer(queueServerRunConfiguration: QueueServerRunConfiguration) throws {
        Logger.info("Generated request signature: \(requestSignature)")
        
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: queueServerRunConfiguration.auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let localQueueServerRunner = LocalQueueServerRunner(
            eventBus: eventBus,
            localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange),
            localQueueVersionProvider: localQueueVersionProvider,
            queueServerRunConfiguration: queueServerRunConfiguration,
            requestSignature: requestSignature
        )
        try localQueueServerRunner.start()
    }
}
