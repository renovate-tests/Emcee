import ArgLib
import Foundation
import Logging
import Models
import PathLib

private let knownArguments: [KnownArguments: ArgumentDescription] = [
    KnownArguments.app: ArgumentDescription(
        name: "app",
        overview: "Location of app that will be tested by the UI tests. If value is missing, tests can be executed only as logic tests",
        optional: true
    ),
    KnownArguments.analyticsConfiguration: ArgumentDescription(
        name: "analytics-configuration",
        overview: "Location of analytics configuration JSON file to support various analytic destinations",
        optional: true
    ),
    KnownArguments.destinationConfigurations: ArgumentDescription(
        name: "destinaton-configurations",
        overview: "A JSON file with additional configuration per destination",
        optional: true
    ),
    KnownArguments.destinations: ArgumentDescription(
        name: "destinations",
        overview: "A JSON file with info about the run destinations for distributed test run"
    ),
    KnownArguments.fbsimctl: ArgumentDescription(
        name: "fbsimctl",
        overview: "Location of fbsimctl tool, or URL to ZIP archive"
    ),
    KnownArguments.fbxctest: ArgumentDescription(
        name: "fbxctest",
        overview: "Location of fbxctest tool, or URL to ZIP archive"
    ),
    KnownArguments.junit: ArgumentDescription(
        name: "junit",
        overview: "Where the combined (the one for all test destinations) Junit report should be created",
        optional: true
    ),
    KnownArguments.output: ArgumentDescription(
        name: "output",
        overview: "Path to where should output be stored as JSON file"
    ),
    KnownArguments.plugin: ArgumentDescription(
        name: "plugin",
        overview: ".emceeplugin bundle location (or URL to ZIP). Plugin bundle should contain an executable: MyPlugin.emceeplugin/Plugin",
        multiple: true,
        optional: true
    ),
    KnownArguments.queueServer: ArgumentDescription(
        name: "queue-server",
        overview: "An address to a server which runs distRun command, e.g. 127.0.0.1:1234"
    ),
    KnownArguments.queueServerDestination: ArgumentDescription(
        name: "queue-server-destination",
        overview: "A JSON file with info about deployment destination which will be used to start remote queue server"
    ),
    KnownArguments.queueServerRunConfigurationLocation: ArgumentDescription(
        name: "queue-server-run-configuration-location",
        overview: "JSON file location which describes QueueServerRunConfiguration. Either /path/to/file.json, or http://example.com/file.zip#path/to/config.json"
    ),
    KnownArguments.remoteScheduleStrategy: ArgumentDescription(
        name: "remote-schedule-strategy",
        overview: "Defines how to scatter tests to the destination machines. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"
    ),
    KnownArguments.runId: ArgumentDescription(
        name: "run-id",
        overview: "A logical test run id, usually a random string, e.g. UUID."
    ),
    KnownArguments.scheduleStrategy: ArgumentDescription(
        name: "schedule-strategy",
        overview: "Defines how to run tests. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"
    ),
    KnownArguments.simulatorLocalizationSettings: ArgumentDescription(
        name: "simulator-localization-settings",
        overview: "Location of JSON file with localization settings",
        optional: true
    ),
    KnownArguments.tempFolder: ArgumentDescription(
        name: "temp-folder",
        overview: "Where to store temporary stuff, including simulator data"
    ),
    KnownArguments.testArgFile: ArgumentDescription(
        name: "test-arg-file",
        overview: "JSON file with description of all tests that expected to be ran.",
        optional: true
    ),
    KnownArguments.testDestinations: ArgumentDescription(
        name: "test-destinations",
        overview: "A JSON file with test destination configurations. For runtime dump only first destination will be used."
    ),
    KnownArguments.trace: ArgumentDescription(
        name: "trace",
        overview: "Where the combined (the one for all test destinations) Chrome trace should be created",
        optional: true
    ),
    KnownArguments.watchdogSettings: ArgumentDescription(
        name: "watchdog-settings",
        overview: "Location of JSON file with watchdog settings",
        optional: true
    ),
    KnownArguments.workerId: ArgumentDescription(
        name: "worker-id",
        overview: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier"
    ),
    KnownArguments.xctestBundle: ArgumentDescription(
        name: "xctest-bundle",
        overview: "Location of .xctest bundle with your tests"
    ),

    KnownArguments.fbxctestSilenceTimeout: ArgumentDescription(
        name: "fbxctest-silence-timeout",
        overview: "A maximum allowed duration for a fbxctest stdout/stderr to be silent",
        optional: true
    ),
    KnownArguments.fbxtestFastTimeout: ArgumentDescription(
        name: "fbxctest-fast-timeout",
        overview: "Overrides fbxtest's internal FastTimeout",
        optional: true
    ),
    KnownArguments.fbxtestRegularTimeout: ArgumentDescription(
        name: "fbxctest-regular-timeout",
        overview: "Overrides fbxtest's internal RegularTimeout",
        optional: true
    ),
    KnownArguments.fbxtestSlowTimeout: ArgumentDescription(
        name: "fbxctest-slow-timeout",
        overview: "Overrides fbxtest's internal SlowTimeout",
        optional: true
    ),
    KnownArguments.fbxtestBundleReadyTimeout: ArgumentDescription(
        name: "fbxctest-bundle-ready-timeout",
        overview: "Overrides fbxtest's internal BundleReady Timeout",
        optional: true
    ),
    KnownArguments.fbxtestCrashCheckTimeout: ArgumentDescription(
        name: "fbxctest-crash-check-timeout",
        overview: "Overrides fbxtest's internal CrashCheck Timeout",
        optional: true
    ),
    KnownArguments.numberOfSimulators: ArgumentDescription(
        name: "number-of-simulators",
        overview: "How many simlutors can be used for running UI tests in parallel"
    ),
    KnownArguments.priority: ArgumentDescription(
        name: "priority",
        overview: "Job priority. Possible values are in range: [0...999]",
        optional: true
    ),
    KnownArguments.singleTestTimeout: ArgumentDescription(
        name: "single-test-timeout",
        overview: "How long each test may run"
    )
]

public enum KnownArguments {
    case additionalApp
    case app
    case analyticsConfiguration
    case destinationConfigurations
    case destinations
    case fbsimctl
    case fbxctest
    case junit
    case output
    case plugin
    case queueServer
    case queueServerDestination
    case queueServerRunConfigurationLocation
    case queueServerTearDownPolicy
    case remoteScheduleStrategy
    case runId
    case runner
    case scheduleStrategy
    case simulatorLocalizationSettings
    case tempFolder
    case testArgFile
    case testDestinations
    case trace
    case watchdogSettings
    case workerId
    case xctestBundle
    
    case fbxctestSilenceTimeout
    case fbxtestBundleReadyTimeout
    case fbxtestCrashCheckTimeout
    case fbxtestFastTimeout
    case fbxtestRegularTimeout
    case fbxtestSlowTimeout
    case numberOfSimulators
    case priority
    case singleTestTimeout
    
    public var argumentDescription: ArgumentDescription {
        return knownArguments[self]!
    }
}

enum ArgumentsError: Error, CustomStringConvertible {
    case argumentIsMissing(KnownArguments)
    case argumentValueCannotBeUsed(String)
    
    var description: String {
        switch self {
        case .argumentIsMissing(let argument):
            return "Missing argument: \(argument.argumentDescription.name). Usage: \(argument.argumentDescription.usage)"
        case .argumentValueCannotBeUsed(let argumentValue):
            return "The provided value for argument cannot be used: '\(argumentValue)'"
        }
    }
}

enum AdditionalArgumentValidationError: Error, CustomStringConvertible {
    case unknownScheduleStrategy(String)
    case notFound(String)
    
    var description: String {
        switch self {
        case .unknownScheduleStrategy(let value):
            return "Unsupported schedule strategy value: \(value). Supported values: \(ScheduleStrategyType.availableRawValues)"
        case .notFound(let path):
            return "File not found: '\(path)'"
        }
    }
}

extension ResourceLocation: ParsableArgument {
    public init(argumentValue: String) throws {
        self = try ResourceLocation.from(argumentValue)
    }
}

public extension TestDestinationConfiguration {
    static func fromFile(path: String) throws -> [TestDestinationConfiguration] {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try ArgumentsReader.decoderWithSnakeCaseSupport.decode(
            [TestDestinationConfiguration].self,
            from: data
        )
    }
}

extension AbsolutePath: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        self.init(argumentValue)
    }
}

extension SocketAddress: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        let socket = try SocketAddress.from(string: argumentValue)
        self.init(host: socket.host, port: socket.port)
    }
}

extension ScheduleStrategyType: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = ScheduleStrategyType(rawValue: argumentValue) else {
            throw ArgumentsError.argumentValueCannotBeUsed(argumentValue)
        }
        self = value
    }
}

extension TestArgFile: ParsableArgument {
    public init(argumentValue: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: argumentValue))
        self = try ArgumentsReader.decoderWithSnakeCaseSupport.decode(TestArgFile.self, from: data)
    }
}

extension Priority: ParsableArgument {
    public convenience init(argumentValue: String) throws {
        try self.init(intValue: try UInt(argumentValue: argumentValue))
    }
}
