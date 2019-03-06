import Foundation
import Models
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import TempFolder

public class FbxctestRunnerSubprocessGenerator: RunnerSubprocessGenerator {
    public init() {}

    public func createSubprocess(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        testContext: TestContext,
        resourceLocationResolver: ResourceLocationResolver,
        runnerBinaryLocation: RunnerBinaryLocation,
        tempFolder: TempFolder,
        testType: TestType
        ) -> Subprocess
    {
        let resolvableFbxctest = resourceLocationResolver.resolvable(resourceLocation: runnerBinaryLocation.resourceLocation)
        var arguments: [SubprocessArgument] =
            [resolvableFbxctest.asArgumentWith(packageName: PackageName.fbxctest),
             "-destination", testContext.simulatorInfo.testDestination.destinationString,
             testType.asArgument]

        let resolvableAppBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.appBundle)
        let resolvableXcTestBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.xcTestBundle)

        switch testType {
        case .logicTest:
            arguments += [resolvableXcTestBundle.asArgument()]
        case .appTest:
            arguments += [
                JoinedSubprocessArgument(
                    components: [resolvableXcTestBundle.asArgument(), resolvableAppBundle.asArgument()],
                    separator: ":"
                )
            ]
        case .uiTest:
            let resolvableRunnerBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.runner)
            let resolvableAdditionalAppBundles = buildArtifacts.additionalApplicationBundles
                .map { resourceLocationResolver.resolvable(withRepresentable: $0) }
            let components = ([resolvableXcTestBundle, resolvableRunnerBundle, resolvableAppBundle] + resolvableAdditionalAppBundles)
                .map { $0.asArgument() }
            arguments += [JoinedSubprocessArgument(components: components, separator: ":")]

            // TODO
//            if let simulatorLocatizationSettings = simulatorSettings.simulatorLocalizationSettings {
//                arguments += [
//                    "-simulator-localization-settings",
//                    resourceLocationResolver.resolvable(withRepresentable: simulatorLocatizationSettings).asArgument()
//                ]
//            }
//            if let watchdogSettings = simulatorSettings.watchdogSettings {
//                arguments += [
//                    "-watchdog-settings",
//                    resourceLocationResolver.resolvable(withRepresentable: watchdogSettings).asArgument()
//                ]
//            }
        }

        arguments += entriesToRun.flatMap {
            ["-only", JoinedSubprocessArgument(components: [resolvableXcTestBundle.asArgument(), $0.testName], separator: ":")]
        }
        arguments += ["run-tests", "-sdk", "iphonesimulator"]
        arguments += ["-workingDirectory", testContext.simulatorInfo.simulatorSetPath.deletingLastPathComponent]
        arguments += ["-keep-simulators-alive"]
        return Subprocess(
            arguments: arguments,
            environment: testContext.environment
        )
    }
}

private extension TestType {
    var asArgument: SubprocessArgument {
        return "-" + self.rawValue
    }
}
