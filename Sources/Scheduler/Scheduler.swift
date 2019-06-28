import Dispatch
import EventBus
import Extensions
import Foundation
import ListeningSemaphore
import Logging
import Models
import ResourceLocationResolver
import Runner
import ScheduleStrategy
import SimulatorPool
import SynchronousWaiter
import TempFolder

public final class Scheduler {
    private let eventBus: EventBus
    private let configuration: SchedulerConfiguration
    private let resourceSemaphore: ListeningSemaphore<ResourceAmounts>
    private var testingResults = [TestingResult]()
    private let queue = OperationQueue()
    private let syncQueue = DispatchQueue(label: "ru.avito.Scheduler")
    private let tempFolder: TemporaryFolder
    private let resourceLocationResolver: ResourceLocationResolver
    private var gatheredErrors = [Error]()
    private weak var schedulerDelegate: SchedulerDelegate?
    
    public init(
        eventBus: EventBus,
        configuration: SchedulerConfiguration,
        tempFolder: TemporaryFolder,
        resourceLocationResolver: ResourceLocationResolver,
        schedulerDelegate: SchedulerDelegate?
        )
    {
        self.eventBus = eventBus
        self.configuration = configuration
        self.resourceSemaphore = ListeningSemaphore(
            maximumValues: .of(
                runningTests: Int(configuration.testRunExecutionBehavior.numberOfSimulators)))
        self.tempFolder = tempFolder
        self.resourceLocationResolver = resourceLocationResolver
        self.schedulerDelegate = schedulerDelegate
    }
    
    public func run() throws -> [TestingResult] {
        startFetchingAndRunningTests()
        try SynchronousWaiter.waitWhile(pollPeriod: 1.0) {
            queue.operationCount > 0 && allGatheredErrors().isEmpty
        }
        if !allGatheredErrors().isEmpty {
            throw SchedulerError.someErrorsHappened(allGatheredErrors())
        }
        return testingResults
    }
    
    // MARK: - Running on Queue
    
    private func startFetchingAndRunningTests() {
        for _ in 0 ..< configuration.testRunExecutionBehavior.numberOfSimulators {
            fetchAndRunBucket()
        }
    }
    
    private func fetchAndRunBucket() {
        queue.addOperation {
            if self.resourceSemaphore.availableResources.runningTests == 0 {
                return
            }
            guard self.allGatheredErrors().isEmpty else {
                Logger.error("Some errors occured, will not fetch and run more buckets")
                for error in self.allGatheredErrors() {
                    Logger.error("\(error)")
                }
                return
            }
            guard let bucket = self.configuration.schedulerDataSource.nextBucket() else {
                Logger.debug("Data Source returned no bucket")
                return
            }
            Logger.debug("Data Source returned bucket: \(bucket)")
            self.runTestsFromFetchedBucket(bucket)
        }
    }
    
    private func runTestsFromFetchedBucket(_ bucket: SchedulerBucket) {
        do {
            let acquireResources = try resourceSemaphore.acquire(.of(runningTests: 1))
            let runTestsInBucketAfterAcquiringResources = BlockOperation {
                do {
                    let testingResult = try self.runRetrying(bucket: bucket)
                    try self.resourceSemaphore.release(.of(runningTests: 1))
                    self.didReceiveResults(testingResult: testingResult)
                    self.schedulerDelegate?.scheduler(self, obtainedTestingResult: testingResult, forBucket: bucket)
                    self.fetchAndRunBucket()
                } catch {
                    self.didFailRunningTests(bucket: bucket, error: error)
                }
            }
            acquireResources.addCascadeCancellableDependency(runTestsInBucketAfterAcquiringResources)
            queue.addOperation(runTestsInBucketAfterAcquiringResources)
        } catch {
            Logger.error("Failed to run tests from bucket \(bucket): \(error)")
        }
    }
    
    private func didReceiveResults(testingResult: TestingResult) {
        syncQueue.sync {
            testingResults.append(testingResult)
        }
    }
    
    private func didFailRunningTests(bucket: SchedulerBucket, error: Error) {
        Logger.error("Error running tests from fetched bucket '\(bucket)' with error: \(error)")
        gather(error: error)
    }
    
    // MARK: - Running the Tests
    
    /**
     Runs tests in a given Bucket, retrying failed tests multiple times if necessary.
     */
    private func runRetrying(bucket: SchedulerBucket) throws -> TestingResult {
        let firstRun = try runBucketOnce(bucket: bucket, testsToRun: bucket.testEntries)
        
        guard bucket.testExecutionBehavior.numberOfRetries > 0 else {
            Logger.debug("numberOfRetries == 0, will not retry failed tests.")
            return firstRun
        }
        
        var lastRunResults = firstRun
        var results = [firstRun]
        for retryNumber in 0 ..< bucket.testExecutionBehavior.numberOfRetries {
            let failedTestEntriesAfterLastRun = lastRunResults.failedTests.map { $0.testEntry }
            if failedTestEntriesAfterLastRun.isEmpty {
                Logger.debug("No failed tests after last retry, so nothing to run.")
                break
            }
            Logger.debug("After last run \(failedTestEntriesAfterLastRun.count) tests have failed: \(failedTestEntriesAfterLastRun).")
            Logger.debug("Retrying them, attempt #\(retryNumber + 1) of maximum \(bucket.testExecutionBehavior.numberOfRetries) attempts")
            lastRunResults = try runBucketOnce(bucket: bucket, testsToRun: failedTestEntriesAfterLastRun)
            results.append(lastRunResults)
        }
        return try combine(runResults: results)
    }
    
    private func runBucketOnce(bucket: SchedulerBucket, testsToRun: [TestEntry]) throws -> TestingResult {
        let simulatorPool = try configuration.onDemandSimulatorPool.pool(
            key: OnDemandSimulatorPool.Key(
                numberOfSimulators: configuration.testRunExecutionBehavior.numberOfSimulators,
                testDestination: bucket.testDestination,
                fbsimctl: bucket.toolResources.fbsimctl
            )
        )

        let allocatedSimulator = try simulatorPool.allocateSimulator()
        defer { allocatedSimulator.releaseSimulator() }
            
        let runner = Runner(
            eventBus: eventBus,
            configuration: RunnerConfiguration(
                testType: bucket.testType,
                fbxctest: bucket.toolResources.fbxctest,
                buildArtifacts: bucket.buildArtifacts,
                environment: bucket.testExecutionBehavior.environment,
                simulatorSettings: bucket.simulatorSettings,
                testTimeoutConfiguration: configuration.testTimeoutConfiguration
            ),
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver
        )

        let runnerResult = try runner.run(
            entries: testsToRun,
            simulator: allocatedSimulator.simulator
        )
        
        if !runnerResult.testEntryResults.filter({ $0.isLost }).isEmpty {
            Logger.warning("Some test results are lost")
            runnerResult.dumpStandardStreams()
        }
        
        return TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: runnerResult.testEntryResults
        )
    }
    
    // MARK: - Utility Methods
    
    /**
     Combines several TestingResult objects of the same Bucket, after running and retrying tests,
     so if some tests become green, the resulting combined object will have it in a green state.
     */
    private func combine(runResults: [TestingResult]) throws -> TestingResult {
        // All successful tests should be merged into a single array.
        // Last run's `failedTests` contains all tests that failed after all attempts to rerun failed tests.
        Logger.verboseDebug("Combining the following results from \(runResults.count) runs:")
        runResults.forEach {
            Logger.verboseDebug("Result: \($0)")
        }
        let result = try TestingResult.byMerging(testingResults: runResults)
        Logger.verboseDebug("Combined result: \(result)")
        return result
    }
    
    private func allGatheredErrors() -> [Error] {
        return syncQueue.sync { gatheredErrors }
    }
    
    private func gather(error: Error) {
        syncQueue.sync { gatheredErrors.append(error) }
    }
}
