import Foundation
import Models

public final class JobStateResponse: Codable {
    public let jobState: JobState

    public init(jobState: JobState) {
        self.jobState = jobState
    }
}
