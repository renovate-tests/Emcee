import Foundation

public struct FbxctestTestEventPair {
    public let startEvent: TestStartedEvent
    public let finishEvent: TestFinishedEvent?

    public init(startEvent: TestStartedEvent, finishEvent: TestFinishedEvent?) {
        self.startEvent = startEvent
        self.finishEvent = finishEvent
    }
}

final class TestEventPairsController {
    private var testPairs = [FbxctestTestEventPair]()
    private let workingQueue = DispatchQueue(label: "ru.avito.runner.TestEventPairsController.workingQueue")
    
    func append(_ pair: FbxctestTestEventPair) {
        workingQueue.sync {
            testPairs.append(pair)
        }
    }
    
    var allPairs: [FbxctestTestEventPair] {
        var results: [FbxctestTestEventPair]?
        workingQueue.sync {
            results = testPairs
        }
        if let results = results {
            return results
        } else {
            return []
        }
    }
    
    var lastPair: FbxctestTestEventPair? {
        var result: FbxctestTestEventPair?
        workingQueue.sync {
            result = testPairs.last
        }
        return result
    }
    
    func popLast() -> FbxctestTestEventPair? {
        var result: FbxctestTestEventPair?
        workingQueue.sync {
            result = testPairs.popLast()
        }
        return result
    }
}
