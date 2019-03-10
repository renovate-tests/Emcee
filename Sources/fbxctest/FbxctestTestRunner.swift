import Foundation
import Models
import ProcessController
import ResourceLocationResolver
import TempFolder
import TestRunner

public final class FbxctestTestRunner: TestRunner {
    private let fbxctestLocation: FbxctestLocation

    public init(fbxctestLocation: FbxctestLocation) {
        self.fbxctestLocation = fbxctestLocation
    }

    public func run(
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
    {
        let fbxctestOutputProcessor = try FbxctestOutputProcessor(
            subprocess: Subprocess(
                arguments: arguments(
                    buildArtifacts: buildArtifacts,
                    entriesToRun: entriesToRun,
                    testContext: testContext,
                    resourceLocationResolver: resourceLocationResolver,
                    fbxctestLocation: fbxctestLocation,
                    tempFolder: tempFolder,
                    testType: testType
                ),
                environment: testContext.environment,
                maximumAllowedSilenceDuration: maximumAllowedSilenceDuration
            ),
            simulatorId: testContext.simulatorInfo.simulatorUuid?.uuidString ?? "unknown uuid", // TODO: make human id
            singleTestMaximumDuration: singleTestMaximumDuration,
            testLifecycleListener: testLifecycleListener
        )
        fbxctestOutputProcessor.processOutputAndWaitForProcessTermination()

        return []
    }

    private func arguments(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        testContext: TestContext,
        resourceLocationResolver: ResourceLocationResolver,
        fbxctestLocation: FbxctestLocation,
        tempFolder: TempFolder,
        testType: TestType
        ) -> [SubprocessArgument]
    {
        let resolvableFbxctest = resourceLocationResolver.resolvable(resourceLocation: fbxctestLocation.resourceLocation)
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

        // TODO: make nicer
        if testContext.simulatorInfo.simulatorUuid != nil {
            arguments += ["-workingDirectory", testContext.simulatorInfo.simulatorSetPath.deletingLastPathComponent]
        }
        arguments += ["-keep-simulators-alive"]
        return arguments
    }
}

private extension TestType {
    var asArgument: SubprocessArgument {
        return "-" + self.rawValue
    }
}
