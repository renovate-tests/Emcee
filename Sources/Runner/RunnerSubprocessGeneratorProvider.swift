import Foundation
import Models
import TestRunner
import Xcodebuild
import fbxctest

public final class TestRunnerProvider {
    public static func createTestRunner(
        runnerBinaryLocation: RunnerBinaryLocation
        ) -> TestRunner
    {
        switch runnerBinaryLocation {
        case .fbxctest(let fbxctestLocation):
            return FbxctestTestRunner(fbxctestLocation: fbxctestLocation)
        case .xcodebuild:
            return XcodebuildTestRunner()
        }
    }
}

