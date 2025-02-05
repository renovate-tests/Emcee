import Foundation
import Models

public enum ResultAcceptanceError: Error, CustomStringConvertible {
    case noDequeuedBucket(requestId: RequestId, workerId: WorkerId)
    
    public var description: String {
        switch self {
        case let .noDequeuedBucket(requestId, workerId):
            return "Cannot accept PushBucketResultRequest with requestId \(requestId) workerId \(workerId). This request does not have corresponding dequeued bucket."
        }
    }
}
