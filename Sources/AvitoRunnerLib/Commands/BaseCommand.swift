import ArgLib
import EventBus
import Foundation
import Models
import OrderedSet
import PathLib
import PluginManager
import ResourceLocationResolver
import RuntimeDump
import SimulatorPool
import TemporaryStuff
import Version

open class BaseCommand: Command {
    open var name: String { fatalError("Subclass must override") }
    open var description: String { fatalError("Subclass must override") }
    public var arguments: Arguments {
        return Arguments(
            OrderedSet(sequence: specificArguments) + OrderedSet(sequence: [
                KnownArguments.plugin.argumentDescription.asOptional,
                KnownArguments.tempFolder.argumentDescription.asOptional
            ])
        )
    }
    open var specificArguments: [ArgumentDescription] { fatalError("Subclass must override") }
    
    public let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    public let requestSignature = RequestSignature(value: UUID().uuidString)
    public let resourceLocationResolver = ResourceLocationResolver()
    
    public func run(payload: CommandPayload) throws {
        let temporaryFolder = try TemporaryFolder(
            containerPath: try payload.optionalTypedValue(argument: .tempFolder)
        )
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: temporaryFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: [
                PluginLocation(try payload.expectedTypedValue(argument: .plugin))   // TODO: support multiple plugins
            ],
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: eventBus,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: temporaryFolder
        )
        
        try run(
            payload: payload, eventBus: eventBus,
            onDemandSimulatorPool: onDemandSimulatorPool,
            runtimeTestQuerier: runtimeTestQuerier,
            temporaryFolder: temporaryFolder
        )
    }
    
    open func run(
        payload: CommandPayload,
        eventBus: EventBus,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        runtimeTestQuerier: RuntimeTestQuerier,
        temporaryFolder: TemporaryFolder
    ) throws {
        fatalError("Subclasses must override this method")
    }
    
    public func setupAnalytics(
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
