import Models
import BucketQueue
import BucketQueueTestHelpers
import ModelsTestHelpers

final class TestHistoryStorageMock: TestHistoryStorage {
    var historyByTest = [TestEntryHistoryId: TestEntryHistory]()
    
    func set(id: TestEntryHistoryId, testEntryHistoryItems: [TestEntryHistoryItem]) {
        historyByTest[id] = TestEntryHistory(
            id: id,
            testEntryHistoryItems: testEntryHistoryItems
        )
    }
    
    func history(id: TestEntryHistoryId) -> TestEntryHistory {
        return historyByTest[id] ?? TestEntryHistory(id: id, testEntryHistoryItems: [])
    }
    
    // Registers attempt, returns updated history of test entry
    func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: WorkerId)
        -> TestEntryHistory
    {
        // do nothing in mock
        let fixtures = TestEntryHistoryFixtures(testEntry: TestEntryFixtures.testEntry())
        return TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testEntryHistoryItems: []
        )
    }
}
