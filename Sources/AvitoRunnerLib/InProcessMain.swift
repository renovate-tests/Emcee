import ArgLib
import EventBus
import Extensions
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import Models
import ProcessController
import ResourceLocationResolver
import RuntimeDump
import SimulatorPool
import TemporaryStuff
import Version

public final class InProcessMain {
    private let eventBus = EventBus()
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>
    private let requestSignature = RequestSignature(value: UUID().uuidString)
    private let resourceLocationResolver = ResourceLocationResolver()
    private let runtimeTestQuerier: RuntimeTestQuerier
    private let temporaryFolder: TemporaryFolder
    
    public init() throws {
        temporaryFolder = try TemporaryFolder()
        onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: temporaryFolder
        )
        runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: eventBus,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: temporaryFolder
        )
    }
    
    public func run() throws {
        try LoggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        defer { LoggingSetup.tearDown() }
        
        Logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")

        let commandInvoker = CommandInvoker(
            commands: [
                DumpRuntimeTestsCommand(
                    eventBus: eventBus,
                    resourceLocationResolver: resourceLocationResolver,
                    runtimeTestQuerier: runtimeTestQuerier,
                    tempFolder: temporaryFolder
                ),
                DistWorkCommand(
                    distWorkerProvider: DefaultDistWorkerProvider(),
                    resourceLocationResolver: resourceLocationResolver
                ),
                RunTestsCommand(),
                StartQueueServerCommand()
            ]
        )
        
        try commandInvoker.invokeSuitableCommand { determinedCommand in
            MetricRecorder.capture(
                LaunchMetric(
                    command: determinedCommand.name,
                    host: LocalHostDeterminer.currentHostAddress
                )
            )
        }
    }
}
