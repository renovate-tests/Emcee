import Foundation
import Models

public final class EnqueuedBucket: Hashable, Comparable, CustomStringConvertible {
    public let bucket: Bucket
    public let enqueueTimestamp: Date
    public let uniqueIdentifier: String

    public init(bucket: Bucket, enqueueTimestamp: Date, uniqueIdentifier: String) {
        self.bucket = bucket
        self.enqueueTimestamp = enqueueTimestamp
        self.uniqueIdentifier = uniqueIdentifier
    }
    
    public var description: String {
        return "<\(type(of: self)) enqueued at: \(enqueueTimestamp) bucket: \(bucket) uniqueIdentifier: \(uniqueIdentifier)>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bucket)
        hasher.combine(enqueueTimestamp)
        hasher.combine(uniqueIdentifier)
    }
    
    public static func == (left: EnqueuedBucket, right: EnqueuedBucket) -> Bool {
        return left.bucket == right.bucket
            && left.enqueueTimestamp == right.enqueueTimestamp
            && left.uniqueIdentifier == right.uniqueIdentifier
    }
    
    public static func < (left: EnqueuedBucket, right: EnqueuedBucket) -> Bool {
        return left.enqueueTimestamp < right.enqueueTimestamp
    }
}
