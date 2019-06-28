import Foundation
import Models
import PathLib

public final class Shimulator: Simulator {
    public static func shimulator(testDestination: TestDestination, workingDirectory: AbsolutePath) -> Shimulator {
        return Shimulator(
            index: 0,
            testDestination: testDestination,
            workingDirectory: workingDirectory
        )
    }
}
