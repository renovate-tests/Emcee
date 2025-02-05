import Foundation

public struct DistRunConfiguration {
    public let analyticsConfigurationLocation: AnalyticsConfigurationLocation?
    
    /** An identifier of distributed run of tests. UUID usually is a good choice. */
    public let runId: JobId
    
    /** The output locations. */
    public let reportOutput: ReportOutput
    
    /** A list of destinations that should be used for distributed run. */
    public let destinations: [DeploymentDestination]
    
    /** A list of additional per-destination configurations. */
    public let destinationConfigurations: [DestinationConfiguration]
    
    /** How to scatter tests onto destinations. */
    public let remoteScheduleStrategyType: ScheduleStrategyType
    
    /** Timeout values. */
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** Deifnes the behavior of the test run. */
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    
    /** Paths that are required to make things work. */
    public let auxiliaryResources: AuxiliaryResources

    /** Some settings that should be applied to the test environment prior running the tests. */
    public let simulatorSettings: SimulatorSettings
    
    /** All test that must be run by the test runner. */
    public let testEntryConfigurations: [TestEntryConfiguration]
    
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    
    /// Period of time when workers should report their aliveness
    public let reportAliveInterval: TimeInterval = 30
    
    public let checkAgainTimeInterval: TimeInterval = 30

    public init(
        analyticsConfigurationLocation: AnalyticsConfigurationLocation?,
        runId: JobId,
        reportOutput: ReportOutput,
        destinations: [DeploymentDestination],
        destinationConfigurations: [DestinationConfiguration],
        remoteScheduleStrategyType: ScheduleStrategyType,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testRunExecutionBehavior: TestRunExecutionBehavior,
        auxiliaryResources: AuxiliaryResources,
        simulatorSettings: SimulatorSettings,
        testEntryConfigurations: [TestEntryConfiguration],
        testDestinationConfigurations: [TestDestinationConfiguration]
        )
    {
        self.analyticsConfigurationLocation = analyticsConfigurationLocation
        self.runId = runId
        self.reportOutput = reportOutput
        self.destinations = destinations
        self.destinationConfigurations = destinationConfigurations
        self.remoteScheduleStrategyType = remoteScheduleStrategyType
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.auxiliaryResources = auxiliaryResources
        self.simulatorSettings = simulatorSettings
        self.testEntryConfigurations = testEntryConfigurations
        self.testDestinationConfigurations = testDestinationConfigurations
    }
    
    public func workerConfiguration(
        destination: DeploymentDestination,
        requestSignature: RequestSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            testRunExecutionBehavior: testRunExecutionBehavior(destination: destination),
            testTimeoutConfiguration: testTimeoutConfiguration,
            pluginUrls: auxiliaryResources.plugins.compactMap { $0.resourceLocation.url },
            reportAliveInterval: reportAliveInterval,
            requestSignature: requestSignature
        )
    }
    
    private func testRunExecutionBehavior(destination: DeploymentDestination) -> TestRunExecutionBehavior {
        let overrides = destinationConfigurations.first { $0.destinationIdentifier.value == destination.identifier }
        
        return TestRunExecutionBehavior(
            numberOfSimulators: overrides?.numberOfSimulators ?? testRunExecutionBehavior.numberOfSimulators,
            scheduleStrategy: testRunExecutionBehavior.scheduleStrategy
        )
    }
}
