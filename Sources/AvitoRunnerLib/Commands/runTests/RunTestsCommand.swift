import ArgLib
import ChromeTracing
import EventBus
import Extensions
import Foundation
import JunitReporting
import Logging
import LoggingSetup
import Models
import PathLib
import PluginManager
import ResourceLocationResolver
import Runner
import RuntimeDump
import ScheduleStrategy
import Scheduler
import SimulatorPool
import TemporaryStuff
import UniqueIdentifierGenerator

public final class RunTestsCommand: BaseCommand {
    public override var name: String { return "runTests" }
    public override var description: String { return "Runs tests on local machine" }
    public override var specificArguments: [ArgumentDescription] {
        return [
            KnownArguments.analyticsConfiguration.argumentDescription,
            KnownArguments.fbsimctl.argumentDescription,
            KnownArguments.fbxctest.argumentDescription,
            KnownArguments.fbxctestSilenceTimeout.argumentDescription,
            KnownArguments.fbxtestBundleReadyTimeout.argumentDescription,
            KnownArguments.fbxtestCrashCheckTimeout.argumentDescription,
            KnownArguments.fbxtestFastTimeout.argumentDescription,
            KnownArguments.fbxtestRegularTimeout.argumentDescription,
            KnownArguments.fbxtestSlowTimeout.argumentDescription,
            KnownArguments.junit.argumentDescription,
            KnownArguments.numberOfSimulators.argumentDescription,
            KnownArguments.scheduleStrategy.argumentDescription,
            KnownArguments.simulatorLocalizationSettings.argumentDescription,
            KnownArguments.singleTestTimeout.argumentDescription,
            KnownArguments.testArgFile.argumentDescription,
            KnownArguments.testDestinations.argumentDescription,
            KnownArguments.trace.argumentDescription,
            KnownArguments.watchdogSettings.argumentDescription
        ]
    }
    
    public override func run(
        payload: CommandPayload,
        eventBus: EventBus,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        runtimeTestQuerier: RuntimeTestQuerier,
        temporaryFolder: TemporaryFolder
    ) throws {
        let analyticsConfigurationLocation = AnalyticsConfigurationLocation(
            try payload.optionalTypedValue(argument: .analyticsConfiguration)
        )
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try setupAnalytics(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        
        let auxiliaryResources = AuxiliaryResources(
            toolResources: ToolResources(
                fbsimctl: FbsimctlLocation(try payload.expectedTypedValue(argument: .fbsimctl)),
                fbxctest: FbxctestLocation(try payload.expectedTypedValue(argument: .fbxctest))
            ),
            plugins: [
                PluginLocation(try payload.expectedTypedValue(argument: .plugin))   // TODO: support multiple plugins
            ]
        )
        
        let reportOutput = ReportOutput(
            junit: try payload.optionalTypedValue(argument: .junit),
            tracingReport: try payload.optionalTypedValue(argument: .trace)
        )
        
        let simulatorSettings = SimulatorSettings(
            simulatorLocalizationSettings: SimulatorLocalizationLocation(
                try payload.optionalTypedValue(argument: .simulatorLocalizationSettings)
            ),
            watchdogSettings: WatchdogSettingsLocation(
                try payload.optionalTypedValue(argument: .watchdogSettings)
            )
        )
        
        let testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: TimeInterval(try payload.expectedTypedValue(argument: .singleTestTimeout)),
            fbxctestSilenceMaximumDuration: (try payload.optionalTypedValue(argument: .fbxctestSilenceTimeout)).map { TimeInterval($0) },
            fbxtestFastTimeout: (try payload.optionalTypedValue(argument: .fbxtestFastTimeout)).map { TimeInterval($0) },
            fbxtestRegularTimeout: (try payload.optionalTypedValue(argument: .fbxtestRegularTimeout)).map { TimeInterval($0) },
            fbxtestSlowTimeout: (try payload.optionalTypedValue(argument: .fbxtestSlowTimeout)).map { TimeInterval($0) },
            fbxtestBundleReadyTimeout: (try payload.optionalTypedValue(argument: .fbxtestBundleReadyTimeout)).map { TimeInterval($0) },
            fbxtestCrashCheckTimeout: (try payload.optionalTypedValue(argument: .fbxtestCrashCheckTimeout)).map { TimeInterval($0) }
        )
        
        let testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfSimulators: try payload.expectedTypedValue(argument: .numberOfSimulators),
            scheduleStrategy: try payload.expectedTypedValue(argument: .scheduleStrategy)
        )
        

        let testArgFile: TestArgFile = try payload.expectedTypedValue(argument: .testArgFile)
        let testDestinationConfigurations = try TestDestinationConfiguration.fromFile(
            path: try payload.expectedTypedValue(argument: .testDestinations)
        )
        
        let validatorConfiguration = TestEntriesValidatorConfiguration(
            fbxctest: auxiliaryResources.toolResources.fbxctest,
            fbsimctl: auxiliaryResources.toolResources.fbsimctl,
            testDestination: testDestinationConfigurations.elementAtIndex(0, "First test destination").testDestination,
            testEntries: testArgFile.entries
        )
        
        let testEntriesValidator = TestEntriesValidator(
            validatorConfiguration: validatorConfiguration,
            runtimeTestQuerier: runtimeTestQuerier
        )
        let validatedTestEntries = try testEntriesValidator.validatedTestEntries()
        
        let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
            validatedEnteries: validatedTestEntries,
            testArgEntries: testArgFile.entries
        )
        
        let configuration = try LocalTestRunConfiguration(
            reportOutput: reportOutput,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testRunExecutionBehavior: testRunExecutionBehavior,
            auxiliaryResources: auxiliaryResources,
            simulatorSettings: simulatorSettings,
            testEntryConfigurations: testEntryConfigurationGenerator.createTestEntryConfigurations(),
            testDestinationConfigurations: testDestinationConfigurations
        )
        try runTests(
            configuration: configuration,
            eventBus: eventBus,
            tempFolder: temporaryFolder,
            onDemandSimulatorPool: onDemandSimulatorPool
        )
    }

    private func runTests(
        configuration: LocalTestRunConfiguration,
        eventBus: EventBus,
        tempFolder: TemporaryFolder,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>
    ) throws {
        Logger.verboseDebug("Configuration: \(configuration)")

        let schedulerConfiguration = SchedulerConfiguration(
            testRunExecutionBehavior: configuration.testRunExecutionBehavior,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration,
            schedulerDataSource: LocalRunSchedulerDataSource(
                configuration: configuration,
                uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator()
            ),
            onDemandSimulatorPool: onDemandSimulatorPool
        )
        let scheduler = Scheduler(
            eventBus: eventBus,
            configuration: schedulerConfiguration,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver,
            schedulerDelegate: nil
        )
        let testingResults = try scheduler.run()
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: configuration.reportOutput,
            testDestinationConfigurations: configuration.testDestinationConfigurations
        ).generateOutput()
    }
}
