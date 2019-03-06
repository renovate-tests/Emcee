import Foundation
import Models

public final class RunnerArgumentListGeneratorProvider {
    public static func runnerSubprocessGenerator(
        runnerBinaryLocation: RunnerBinaryLocation
        ) -> RunnerSubprocessGenerator
    {
        switch runnerBinaryLocation {
        case .fbxctest:
            return FbxctestRunnerSubprocessGenerator()
        case .xcodebuild:
            return XcodebuildRunnerSubprocessGenerator()
        }
    }
}

