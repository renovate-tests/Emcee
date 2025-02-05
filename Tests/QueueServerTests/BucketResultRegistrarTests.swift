import BucketQueueTestHelpers
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import ResultsCollector
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class BucketResultRegistrarTests: XCTestCase {
    let eventBus = EventBus()
    let expectedRequestSignature = RequestSignature(value: "expectedRequestSignature")
    let testingResult = TestingResultFixtures()
        .with(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "method"))
        .addingLostResult()
        .testingResult()

    func test__results_collector_receives_results__if_bucket_queue_accepts_results() {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        
        let registrar = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedRequestSignature: expectedRequestSignature,
            workerAlivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        )
        
        let request = PushBucketResultRequest(
            workerId: "worker",
            requestId: "request",
            testingResult: testingResult,
            requestSignature: expectedRequestSignature
        )
        XCTAssertNoThrow(try registrar.handle(decodedRequest: request))
        
        XCTAssertEqual(bucketQueue.acceptedResults, [testingResult])
    }
    
    func test___results_collector_stays_unmodified___if_bucket_queue_does_not_accept_results() {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        alivenessTracker.didRegisterWorker(workerId: "worker")
        let bucketQueue = FakeBucketQueue(throwsOnAccept: true)
        
        let registrar = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedRequestSignature: expectedRequestSignature,
            workerAlivenessTracker: alivenessTracker
        )
        
        let request = PushBucketResultRequest(
            workerId: "worker",
            requestId: "request",
            testingResult: testingResult,
            requestSignature: expectedRequestSignature
        )
        XCTAssertThrowsError(try registrar.handle(decodedRequest: request))
        
        XCTAssertEqual(bucketQueue.acceptedResults, [])
    }

    func test___throws___when_expected_request_signature_mismatch() {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        alivenessTracker.didRegisterWorker(workerId: "worker")
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)

        let registrar = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedRequestSignature: expectedRequestSignature,
            workerAlivenessTracker: alivenessTracker
        )

        XCTAssertThrowsError(
            try registrar.handle(
                decodedRequest: PushBucketResultRequest(
                    workerId: "worker",
                    requestId: "request",
                    testingResult: testingResult,
                    requestSignature: RequestSignature(value: UUID().uuidString)
                )
            ),
            "When request signature mismatches, bucket provider endpoind should throw"
        )
    }
}

