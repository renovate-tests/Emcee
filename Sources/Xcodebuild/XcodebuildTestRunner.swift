import Foundation
import Models
import ResourceLocationResolver
import TestRunner
import TempFolder

public final class XcodebuildTestRunner: TestRunner {
    public init() {
    }

    public func run(buildArtifacts: BuildArtifacts, entriesToRun: [TestEntry], maximumAllowedSilenceDuration: TimeInterval, resourceLocationResolver: ResourceLocationResolver, singleTestMaximumDuration: TimeInterval, testContext: TestContext, tempFolder: TempFolder, testLifecycleListener: TestLifecycleListener, testType: TestType) -> [TestEventPair] {
        return []
    }
}

