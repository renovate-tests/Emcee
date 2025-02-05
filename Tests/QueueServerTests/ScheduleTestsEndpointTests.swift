import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import ScheduleStrategy
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class ScheduleTestsEndpointTests: XCTestCase {
    private let fixedBucketId: BucketId = "fixedBucketId"
    private lazy var individualBucketSplitter = IndividualBucketSplitter(
        uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(
            value: fixedBucketId.value
        )
    )

    func test___scheduling_tests() throws {
        let endpoint = ScheduleTestsEndpoint(testsEnqueuer: testsEnqueuer)
        let response = try endpoint.handle(
            decodedRequest: ScheduleTestsRequest(
                requestId: requestId,
                prioritizedJob: prioritizedJob,
                testEntryConfigurations: testEntryConfigurations
            )
        )
        
        XCTAssertEqual(response, ScheduleTestsResponse.scheduledTests(requestId: requestId))
        
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[prioritizedJob],
            [
                BucketFixtures.createBucket(
                    bucketId: fixedBucketId,
                    testEntries: [TestEntryFixtures.testEntry()]
                )
            ]
        )
    }
    
    func test___scheduling_tests_with_same_request_id___does_not_schedule_multiple_times() throws {
        let endpoint = ScheduleTestsEndpoint(testsEnqueuer: testsEnqueuer)
        for _ in 0 ... 10 {
            _ = try endpoint.handle(
                decodedRequest: ScheduleTestsRequest(
                    requestId: requestId,
                    prioritizedJob: prioritizedJob,
                    testEntryConfigurations: testEntryConfigurations
                )
            )
        }
        
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[prioritizedJob],
            [
                BucketFixtures.createBucket(
                    bucketId: fixedBucketId,
                    testEntries: [TestEntryFixtures.testEntry()]
                )
            ]
        )
    }

    let bucketSplitInfo = BucketSplitInfo(
        numberOfWorkers: 0,
        toolResources: ToolResourcesFixtures.fakeToolResources(),
        simulatorSettings: SimulatorSettingsFixtures().simulatorSettings()
    )
    let jobId = JobId(value: "jobId")
    lazy var prioritizedJob = PrioritizedJob(jobId: jobId, priority: .medium)
    let requestId: RequestId = "requestId"
    let testEntryConfigurations = TestEntryConfigurationFixtures()
        .add(testEntry: TestEntryFixtures.testEntry())
        .testEntryConfigurations()
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    lazy var testsEnqueuer = TestsEnqueuer(
        bucketSplitter: individualBucketSplitter,
        bucketSplitInfo: bucketSplitInfo,
        enqueueableBucketReceptor: enqueueableBucketReceptor
    )
    
}
