import Dispatch
import Foundation
import Logging
import Models
import RESTMethods
import SynchronousWaiter
import Version

public final class SynchronousQueueClient: QueueClientDelegate {
    public enum BucketFetchResult: Equatable {
        case bucket(Bucket)
        case queueIsEmpty
        case checkLater(TimeInterval)
        case workerHasBeenBlocked
        case workerConsideredNotAlive
    }
    
    private let queueClient: QueueClient
    private var registrationResult: Either<WorkerConfiguration, QueueClientError>?
    private var bucketFetchResult: Either<BucketFetchResult, QueueClientError>?
    private var bucketResultSendResult: Either<BucketId, QueueClientError>?
    private var alivenessReportResult: Either<Bool, QueueClientError>?
    private var queueServerVersionResult: Either<Version, QueueClientError>?
    private var scheduleTestsResult: Either<RequestId, QueueClientError>?
    private var jobResultsResult: Either<JobResults, QueueClientError>?
    private var jobStateResult: Either<JobState, QueueClientError>?
    private var jobDeleteResult: Either<JobId, QueueClientError>?
    private let syncQueue = DispatchQueue(label: "ru.avito.SynchronousQueueClient")
    private let requestTimeout: TimeInterval
    private let networkRequestRetryCount: Int
    
    public init(
        queueServerAddress: SocketAddress,
        requestTimeout: TimeInterval = 10,
        networkRequestRetryCount: Int = 5)
    {
        self.requestTimeout = requestTimeout
        self.networkRequestRetryCount = networkRequestRetryCount
        self.queueClient = QueueClient(queueServerAddress: queueServerAddress)
        self.queueClient.delegate = self
    }
    
    public func close() {
        queueClient.close()
    }
    
    // MARK: Public API
    
    public func registerWithServer(workerId: WorkerId) throws -> WorkerConfiguration {
        return try synchronize {
            registrationResult = nil
            try queueClient.registerWithServer(workerId: workerId)
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for registration with server") {
                self.registrationResult == nil
            }
            return try registrationResult!.dematerialize()
        }
    }
    
    public func fetchBucket(requestId: RequestId, workerId: WorkerId, requestSignature: RequestSignature) throws -> BucketFetchResult {
        return try synchronize {
            bucketFetchResult = nil
            return try runRetrying {
                try queueClient.fetchBucket(requestId: requestId, workerId: workerId, requestSignature: requestSignature)
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait bucket to return from server") {
                    self.bucketFetchResult == nil
                }
                return try bucketFetchResult!.dematerialize()
            }
        }
    }
    
    public func send(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId, requestSignature: RequestSignature) throws -> BucketId {
        return try synchronize {
            bucketResultSendResult = nil
            return try runRetrying {
                try queueClient.send(
                    testingResult: testingResult,
                    requestId: requestId,
                    workerId: workerId,
                    requestSignature: requestSignature
                )
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for bucket result send") {
                    self.bucketResultSendResult == nil
                }
                return try bucketResultSendResult!.dematerialize()
            }
        }
    }
    
    public func reportAliveness(bucketIdsBeingProcessedProvider: @autoclosure () -> (Set<BucketId>), workerId: WorkerId, requestSignature: RequestSignature) throws {
        try synchronize {
            alivenessReportResult = nil
            try runRetrying {
                try queueClient.reportAlive(
                    bucketIdsBeingProcessedProvider: bucketIdsBeingProcessedProvider(),
                    workerId: workerId,
                    requestSignature: requestSignature
                )
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for aliveness report") {
                    self.alivenessReportResult == nil
                }
            } as Void
        } as Void
    }
    
    public func fetchQueueServerVersion() throws -> Version {
        return try synchronize {
            queueServerVersionResult = nil
            try queueClient.fetchQueueServerVersion()
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for queue server version") {
                self.queueServerVersionResult == nil
            }
            return try queueServerVersionResult!.dematerialize()
        }
    }
    
    public func scheduleTests(
        prioritizedJob: PrioritizedJob,
        testEntryConfigurations: [TestEntryConfiguration],
        requestId: RequestId)
        throws -> RequestId
    {
        return try synchronize {
            scheduleTestsResult = nil
            return try runRetrying {
                try queueClient.scheduleTests(
                    prioritizedJob: prioritizedJob,
                    testEntryConfigurations: testEntryConfigurations,
                    requestId: requestId
                )
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for tests to be scheduled") {
                    self.scheduleTestsResult == nil
                }
                return try scheduleTestsResult!.dematerialize()
            }
        }
    }
    
    public func jobResults(jobId: JobId) throws -> JobResults {
        return try synchronize {
            jobResultsResult = nil
            return try runRetrying {
                try queueClient.fetchJobResults(jobId: jobId)
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for \(jobId) job results") {
                    self.jobResultsResult == nil
                }
                return try jobResultsResult!.dematerialize()
            }
        }
    }
    
    public func jobState(jobId: JobId) throws -> JobState {
        return try synchronize {
            jobStateResult = nil
            return try runRetrying {
                try queueClient.fetchJobState(jobId: jobId)
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for \(jobId) job state") {
                    self.jobStateResult == nil
                }
                return try jobStateResult!.dematerialize()
            }
        }
    }
    
    public func delete(jobId: JobId) throws -> JobId {
        return try synchronize {
            jobDeleteResult = nil
            try queueClient.deleteJob(jobId: jobId)
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for job \(jobId) to be deleted") {
                self.jobDeleteResult == nil
            }
            return try jobDeleteResult!.dematerialize()
        }
    }
    
    // MARK: - Private
    
    private func synchronize<T>(_ work: () throws -> T) rethrows -> T {
        return try syncQueue.sync {
            return try work()
        }
    }
    
    private func runRetrying<T>(_ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< networkRequestRetryCount {
            Logger.verboseDebug("Attempting to send request: #\(retryIndex + 1) of \(networkRequestRetryCount)")
            do {
                return try work()
            } catch {
                Logger.error("Failed to send request with error: \(error)")
                SynchronousWaiter.wait(timeout: 1.0)
            }
        }
        return try work()
    }
    
    // MARK: - Queue Delegate
    
    public func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        registrationResult = Either.error(error)
        bucketFetchResult = Either.error(error)
        alivenessReportResult = Either.error(error)
        bucketResultSendResult = Either.error(error)
        queueServerVersionResult = Either.error(error)
        scheduleTestsResult = Either.error(error)
        jobResultsResult = Either.error(error)
        jobStateResult = Either.error(error)
        jobDeleteResult = Either.error(error)
    }
    
    public func queueClient(_ sender: QueueClient, didReceiveWorkerConfiguration workerConfiguration: WorkerConfiguration) {
        registrationResult = Either.success(workerConfiguration)
    }
    
    public func queueClientQueueIsEmpty(_ sender: QueueClient) {
        bucketFetchResult = Either.success(.queueIsEmpty)
    }
    
    public func queueClientWorkerConsideredNotAlive(_ sender: QueueClient) {
        bucketFetchResult = Either.success(.workerConsideredNotAlive)
    }
    
    public func queueClientWorkerHasBeenBlocked(_ sender: QueueClient) {
        bucketFetchResult = Either.success(.workerHasBeenBlocked)
    }
    
    public func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval) {
        bucketFetchResult = Either.success(.checkLater(after))
    }
    
    public func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket) {
        bucketFetchResult = Either.success(.bucket(bucket))
    }
    
    public func queueClient(_ sender: QueueClient, serverDidAcceptBucketResult bucketId: BucketId) {
        bucketResultSendResult = Either.success(bucketId)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchQueueServerVersion version: Version) {
        queueServerVersionResult = Either.success(version)
    }
    
    public func queueClientWorkerHasBeenIndicatedAsAlive(_ sender: QueueClient) {
        alivenessReportResult = Either.success(true)
    }
    
    public func queueClientDidScheduleTests(_ sender: QueueClient, requestId: RequestId) {
        scheduleTestsResult = Either.success(requestId)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchJobState jobState: JobState) {
        jobStateResult = Either.success(jobState)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults) {
        jobResultsResult = Either.success(jobResults)
    }
    
    public func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId) {
        jobDeleteResult = Either.success(jobId)
    }
}
