import ArgLib
import ChromeTracing
import DistRunner
import EventBus
import Extensions
import Foundation
import JunitReporting
import Logging
import Models
import PathLib
import ResourceLocationResolver
import RuntimeDump
import ScheduleStrategy
import Scheduler
import SimulatorPool
import TemporaryStuff

public final class DumpRuntimeTestsCommand: Command {
    public let name = "dump"
    public let description = "Dumps all available runtime tests into JSON file"
    public let arguments: Arguments = [
        KnownArguments.app.argumentDescription.asOptional,
        KnownArguments.fbsimctl.argumentDescription.asOptional,
        KnownArguments.fbxctest.argumentDescription,
        KnownArguments.output.argumentDescription,
        KnownArguments.testDestinations.argumentDescription,
        KnownArguments.xctestBundle.argumentDescription
    ]
    
    private let eventBus: EventBus
    private let resourceLocationResolver: ResourceLocationResolver
    private let runtimeTestQuerier: RuntimeTestQuerier
    private let tempFolder: TemporaryFolder

    public init(
        eventBus: EventBus,
        resourceLocationResolver: ResourceLocationResolver,
        runtimeTestQuerier: RuntimeTestQuerier,
        tempFolder: TemporaryFolder
    ) {
        self.eventBus = eventBus
        self.resourceLocationResolver = resourceLocationResolver
        self.runtimeTestQuerier = runtimeTestQuerier
        self.tempFolder = tempFolder
    }
    
    public func run(payload: CommandPayload) throws {
        let fbxctest: ResourceLocation = try payload.expectedTypedValue(argument: .fbxctest)
        let output: AbsolutePath = try payload.expectedTypedValue(argument: .output)
        let testDestinationConfigiurations = try TestDestinationConfiguration.fromFile(
            path: try payload.expectedTypedValue(argument: .testDestinations)
        )
        let xctestBundle: ResourceLocation = try payload.expectedTypedValue(argument: .xctestBundle)
        let applicationTestSupport = try runtimeDumpApplicationTestSupport(payload: payload)
        let runtimeDumpKind: RuntimeDumpKind = applicationTestSupport != nil ? .appTest : .logicTest

        let configuration = RuntimeDumpConfiguration(
            fbxctest: FbxctestLocation(fbxctest),
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(xctestBundle),
                runtimeDumpKind: runtimeDumpKind
            ),
            applicationTestSupport: applicationTestSupport,
            testDestination: testDestinationConfigiurations[0].testDestination,
            testsToValidate: []
        )

        let runtimeTests = try runtimeTestQuerier.queryRuntime(configuration: configuration)
        let encodedTests = try JSONEncoder.pretty().encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: output.fileUrl, options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(output)")
    }

    private func runtimeDumpApplicationTestSupport(
        payload: CommandPayload
    ) throws -> RuntimeDumpApplicationTestSupport? {
        let appLocation: ResourceLocation? = try payload.optionalTypedValue(argument: .app)
        let fbsimctlLocation: ResourceLocation? = try payload.optionalTypedValue(argument: .fbsimctl)

        guard appLocation != nil else {
            if fbsimctlLocation != nil {
                Logger.warning(
                    "--fbsimctl argument is unused. To support application test runtime dump mode both --fbsimctl and --app should be provided."
                )
            }
            return nil
        }

        guard let app = appLocation, let fbsimctl = fbsimctlLocation else {
            throw DumpCommandConfigurationError.bothAppAndFbsimctlRequired
        }

        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(app),
            fbsimctl: FbsimctlLocation(fbsimctl)
        )
    }
}
