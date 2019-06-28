import ArgumentsParser
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
import TempFolder
import UniqueIdentifierGenerator
import Utility

final class RunTestsCommand: Command {
    let command = "runTests"
    let overview = "Runs UI tests and writes report"

    private let analyticsConfigurationLocation: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let fbxctest: OptionArgument<String>
    private let fbxctestSilenceTimeout: OptionArgument<UInt>
    private let fbxtestBundleReadyTimeout: OptionArgument<UInt>
    private let fbxtestCrashCheckTimeout: OptionArgument<UInt>
    private let fbxtestFastTimeout: OptionArgument<UInt>
    private let fbxtestRegularTimeout: OptionArgument<UInt>
    private let fbxtestSlowTimeout: OptionArgument<UInt>
    private let junit: OptionArgument<String>
    private let numberOfSimulators: OptionArgument<UInt>
    private let plugins: OptionArgument<[String]>
    private let scheduleStrategy: OptionArgument<String>
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let singleTestTimeout: OptionArgument<UInt>
    private let tempFolder: OptionArgument<String>
    private let testArgFile: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let trace: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)

        analyticsConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.analyticsConfiguration)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        fbxctestSilenceTimeout = subparser.add(intArgument: KnownUIntArguments.fbxctestSilenceTimeout)
        fbxtestBundleReadyTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestBundleReadyTimeout)
        fbxtestCrashCheckTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestCrashCheckTimeout)
        fbxtestFastTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestFastTimeout)
        fbxtestRegularTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestRegularTimeout)
        fbxtestSlowTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestSlowTimeout)
        junit = subparser.add(stringArgument: KnownStringArguments.junit)
        numberOfSimulators = subparser.add(intArgument: KnownUIntArguments.numberOfSimulators)
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        scheduleStrategy = subparser.add(stringArgument: KnownStringArguments.scheduleStrategy)
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
        testArgFile = subparser.add(stringArgument: KnownStringArguments.testArgFile)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let analyticsConfigurationLocation = AnalyticsConfigurationLocation(
            try ArgumentsReader.validateResourceLocationOrNil(arguments.get(self.analyticsConfigurationLocation), key: KnownStringArguments.analyticsConfiguration)
        )
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try AnalyticsConfigurator(resourceLocationResolver: resourceLocationResolver)
                .setup(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        
        let auxiliaryResources = AuxiliaryResources(
            toolResources: ToolResources(
                fbsimctl: FbsimctlLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)),
                fbxctest: FbxctestLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest))
            ),
            plugins: try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin).map({ PluginLocation($0) })
        )
        let reportOutput = ReportOutput(
            junit: arguments.get(self.junit),
            tracingReport: arguments.get(self.trace)
        )
        let simulatorSettings = try ArgumentsReader.simulatorSettings(
            localizationFile: arguments.get(self.simulatorLocalizationSettings),
            localizationKey: KnownStringArguments.simulatorLocalizationSettings,
            watchdogFile: arguments.get(self.watchdogSettings),
            watchdogKey: KnownStringArguments.watchdogSettings
        )
        
        let testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: TimeInterval(try ArgumentsReader.validateNotNil(arguments.get(self.singleTestTimeout), key: KnownUIntArguments.singleTestTimeout)),
            fbxctestSilenceMaximumDuration: arguments.get(self.fbxctestSilenceTimeout).map { TimeInterval($0) },
            fbxtestFastTimeout: arguments.get(self.fbxtestFastTimeout).map { TimeInterval($0) },
            fbxtestRegularTimeout: arguments.get(self.fbxtestRegularTimeout).map { TimeInterval($0) },
            fbxtestSlowTimeout: arguments.get(self.fbxtestSlowTimeout).map { TimeInterval($0) },
            fbxtestBundleReadyTimeout: arguments.get(self.fbxtestBundleReadyTimeout).map { TimeInterval($0) },
            fbxtestCrashCheckTimeout: arguments.get(self.fbxtestCrashCheckTimeout).map { TimeInterval($0) }
        )
        let testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfSimulators: try ArgumentsReader.validateNotNil(arguments.get(self.numberOfSimulators), key: KnownUIntArguments.numberOfSimulators),
            scheduleStrategy: try ArgumentsReader.scheduleStrategy(arguments.get(self.scheduleStrategy), key: KnownStringArguments.scheduleStrategy)
        )
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let tempFolder = try TemporaryFolder(containerPath: AbsolutePath(try ArgumentsReader.validateNotNil(arguments.get(self.tempFolder), key: KnownStringArguments.tempFolder)))
        let testArgFile = try ArgumentsReader.testArgFile(arguments.get(self.testArgFile), key: KnownStringArguments.testArgFile)
        let testDestinationConfigurations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)

        let validatorConfiguration = TestEntriesValidatorConfiguration(
            fbxctest: auxiliaryResources.toolResources.fbxctest,
            fbsimctl: auxiliaryResources.toolResources.fbsimctl,
            testDestination: testDestinationConfigurations.elementAtIndex(0, "First test destination").testDestination,
            testEntries: testArgFile.entries
        )
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        defer { onDemandSimulatorPool.deleteSimulators() }
        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: eventBus,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder
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
            tempFolder: tempFolder,
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
