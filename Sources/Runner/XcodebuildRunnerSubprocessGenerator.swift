import Foundation
import Logging
import Models
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import TempFolder
import XcTestRun

public final class XcodebuildRunnerSubprocessGenerator: RunnerSubprocessGenerator {
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
        let arguments: [SubprocessArgument] = [
            resourceLocationResolver.resolvable(resourceLocation: runnerBinaryLocation.resourceLocation).asArgument(),
            "test-without-building",
            "-destination", XcodebuildSimulatorDestinationArgument(
                simulatorInfo: testContext.simulatorInfo,
                testType: testType
            ),
            "-xctestrun", XcTestRunFileArgument(
                buildArtifacts: buildArtifacts,
                entriesToRun: entriesToRun,
                environmentForTests: testContext.environment,
                resourceLocationResolver: resourceLocationResolver,
                testType: testType,
                tempFolder: tempFolder
            )
        ]
        return Subprocess(arguments: arguments)
    }
}

private class XcodebuildSimulatorDestinationArgument: SubprocessArgument {
    private let simulatorInfo: SimulatorInfo
    private let testType: TestType

    public init(simulatorInfo: SimulatorInfo, testType: TestType) {
        self.simulatorInfo = simulatorInfo
        self.testType = testType
    }

    func stringValue() throws -> String {
        if testType == .logicTest {
            let testDestination = simulatorInfo.testDestination
            return "platform=iOS Simulator,name=\(testDestination.deviceType),OS=\(testDestination.runtime)"
        }

        guard let uuid = simulatorInfo.simulatorUuid else {
            struct CannotDetermineSimulatorUuid: Error, CustomStringConvertible {
                let simulatorInfo: SimulatorInfo

                var description: String {
                    return "Cannot determine UUID of simulator \(simulatorInfo)"
                }
            }
            throw CannotDetermineSimulatorUuid(simulatorInfo: simulatorInfo)
        }
        return "platform=iOS Simulator,id=\(uuid.uuidString)"
    }
}

private class XcTestRunFileArgument: SubprocessArgument {
    private let buildArtifacts: BuildArtifacts
    private let entriesToRun: [TestEntry]
    private let environmentForTests: [String: String]
    private let resourceLocationResolver: ResourceLocationResolver
    private let testType: TestType
    private let tempFolder: TempFolder

    public init(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        environmentForTests: [String: String],
        resourceLocationResolver: ResourceLocationResolver,
        testType: TestType,
        tempFolder: TempFolder
        )
    {
        self.buildArtifacts = buildArtifacts
        self.entriesToRun = entriesToRun
        self.environmentForTests = environmentForTests
        self.resourceLocationResolver = resourceLocationResolver
        self.testType = testType
        self.tempFolder = tempFolder
    }

    func stringValue() throws -> String {
        let xcTestRun = try createXcTestRun()

        let xcTestRunPlist = XcTestRunPlist(xcTestRun: xcTestRun)

        let plistPath = try tempFolder.createFile(
            components: ["xctestrun"],
            filename: UUID().uuidString + ".xctestrun",
            contents: try xcTestRunPlist.createPlistData()
        )
        Logger.always("xcrun: \(plistPath)")
        return plistPath.asString
    }

    private func createXcTestRun() throws -> XcTestRun {
        switch testType {
        case .uiTest:
            return try xcTestRunForUiTesting()
        case .logicTest:
            return try xcTestRunForLogicTesting()
        case .appTest:
            return try xcTestRunForApplicationTesting()
        }
    }

    private func xcTestRunForLogicTesting() throws -> XcTestRun {
        let testHost = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Xcode/Agents/xctest" // TODO - unhardcode
        let testBundlePath = try resourceLocationResolver.resolvable(resourceLocation: buildArtifacts.xcTestBundle.resourceLocation).resolve().directlyAccessibleResourcePath()
        let xctestSpecificEnvironment = [
            "DYLD_INSERT_LIBRARIES": "__PLATFORMS__/iPhoneSimulator.platform/Developer/usr/lib/libXCTestBundleInject.dylib",
            "XCInjectBundleInto": testHost
        ]

        return XcTestRun(
            testTargetName: "StubTargetName",
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [],
            testBundlePath: testBundlePath,
            testHostPath: testHost,
            testHostBundleIdentifier: "StubBundleId", // TODO - check if this works
            uiTargetAppPath: nil,
            environmentVariables: [:],
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: [:],
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName },
            testingEnvironmentVariables: xctestSpecificEnvironment.byMergingWith(environmentForTests),
            isUITestBundle: false,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: false
        )
    }

    private func xcTestRunForApplicationTesting() throws -> XcTestRun {
        let hostAppPath = try resourceLocationResolver.resolvable(resourceLocation: buildArtifacts.appBundle.resourceLocation).resolve().directlyAccessibleResourcePath()
        let testBundlePath = try resourceLocationResolver.resolvable(resourceLocation: buildArtifacts.xcTestBundle.resourceLocation).resolve().directlyAccessibleResourcePath()

        return XcTestRun(
            testTargetName: "StubTargetName",
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [],
            testBundlePath: testBundlePath,
            testHostPath: hostAppPath,
            testHostBundleIdentifier: "StubBundleId", // TODO - check if this works
            uiTargetAppPath: nil,
            environmentVariables: [:],
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: [:],
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName },
            testingEnvironmentVariables: [:],
            isUITestBundle: false,
            isAppHostedTestBundle: true,
            isXCTRunnerHostedTestBundle: false
        )
    }

    private func xcTestRunForUiTesting() throws -> XcTestRun {
        let uiTargetAppPath = try resourceLocationResolver.resolvable(resourceLocation: buildArtifacts.appBundle.resourceLocation).resolve().directlyAccessibleResourcePath()
        let testBundlePath = try resourceLocationResolver.resolvable(resourceLocation: buildArtifacts.xcTestBundle.resourceLocation).resolve().directlyAccessibleResourcePath()
        let hostAppPath = try resourceLocationResolver.resolvable(resourceLocation: buildArtifacts.runner.resourceLocation).resolve().directlyAccessibleResourcePath()

        let dependentProductPaths: [String] = try buildArtifacts.additionalApplicationBundles.map {
            try resourceLocationResolver.resolvable(resourceLocation: $0.resourceLocation).resolve().directlyAccessibleResourcePath()
        } + [uiTargetAppPath]

        return XcTestRun(
            testTargetName: "StubTargetName",
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: dependentProductPaths,
            testBundlePath: testBundlePath,
            testHostPath: hostAppPath,
            testHostBundleIdentifier: "StubBundleId", // TODO - check if this works
            uiTargetAppPath: uiTargetAppPath,
            environmentVariables: [:],
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: [:],
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName },
            testingEnvironmentVariables: [
                "DYLD_FRAMEWORK_PATH": "__PLATFORMS__/iPhoneOS.platform/Developer/Library/Frameworks",
                "DYLD_LIBRARY_PATH": "__PLATFORMS__/iPhoneOS.platform/Developer/Library/Frameworks"
            ],
            isUITestBundle: true,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: true
        )
    }
}
