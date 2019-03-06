import Foundation
import Models
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import TempFolder

public protocol RunnerSubprocessGenerator {
    func createSubprocess(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        testContext: TestContext,
        resourceLocationResolver: ResourceLocationResolver,
        runnerBinaryLocation: RunnerBinaryLocation,
        tempFolder: TempFolder,
        testType: TestType
        ) -> Subprocess
}
