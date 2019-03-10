import Foundation
import Models
import ResourceLocationResolver
import TempFolder

public protocol TestRunner {
    func run(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        maximumAllowedSilenceDuration: TimeInterval,
        resourceLocationResolver: ResourceLocationResolver,
        singleTestMaximumDuration: TimeInterval,
        testContext: TestContext,
        tempFolder: TempFolder,
        testLifecycleListener: TestLifecycleListener,
        testType: TestType
        ) throws -> [TestEventPair]
}
