import ArgLib
import Foundation
import LocalQueueServerRunner
import Logging
import Models
import ResourceLocationResolver

final class ArgumentsReader {
    private init() {}
    
    public static let decoderWithSnakeCaseSupport: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    private static let strictDecoder = JSONDecoder()
    
//    public static func environment(_ file: String?) throws -> [String: String] {
//        return try decodeModelsFromFile(file, defaultValueIfFileIsMissing: [:], jsonDecoder: strictDecoder)
//    }
//    
//    public static func testArgFile(_ file: String?) throws -> TestArgFile {
//        return try decodeModelsFromFile(file, defaultValueIfFileIsMissing: TestArgFile(entries: []), jsonDecoder: strictDecoder)
//    }
//    
//    public static func testDestinations(_ file: String) throws -> [TestDestinationConfiguration] {
//        return try decodeModelsFromFile(file, jsonDecoder: decoderWithSnakeCaseSupport)
//    }
//    
//    public static func deploymentDestinations(_ file: String?) throws -> [DeploymentDestination] {
//        return try decodeModelsFromFile(file, jsonDecoder: decoderWithSnakeCaseSupport)
//    }
//    
//    public static func destinationConfigurations(_ file: String?) throws -> [DestinationConfiguration] {
//        return try decodeModelsFromFile(file, defaultValueIfFileIsMissing: [], jsonDecoder: decoderWithSnakeCaseSupport)
//    }
//    
//    public static func simulatorSettings(
//        localizationFile: String?,
//        watchdogFile: String?
//    ) throws -> SimulatorSettings {
//        let localizationResource = try validateResourceLocationOrNil(localizationFile)
//        var localizationLocation: SimulatorLocalizationLocation?
//        if let localizationResource = localizationResource {
//            localizationLocation = SimulatorLocalizationLocation(localizationResource)
//        }
//        
//        let watchdogResource = try validateResourceLocationOrNil(watchdogFile)
//        var watchdogLocation: WatchdogSettingsLocation?
//        if let watchdogResource = watchdogResource {
//            watchdogLocation = WatchdogSettingsLocation(watchdogResource)
//        }
//        return SimulatorSettings(simulatorLocalizationSettings: localizationLocation, watchdogSettings: watchdogLocation)
//    }
//
//    public static func queueServerRunConfiguration(
//        _ value: String?,
//        resourceLocationResolver: ResourceLocationResolver)
//        throws -> QueueServerRunConfiguration
//    {
//        let location = try ArgumentsReader.validateResourceLocation(value)
//        let resolvingResult = try resourceLocationResolver.resolvePath(resourceLocation: location)
//        return try decodeModelsFromFile(
//            try resolvingResult.directlyAccessibleResourcePath(),
//            jsonDecoder: decoderWithSnakeCaseSupport
//        )
//    }
//    
//    private static func decodeModelsFromFile<T>(
//        _ file: String?,
//        defaultValueIfFileIsMissing: T? = nil,
//        jsonDecoder: JSONDecoder) throws -> T where T: Decodable {
//        if file == nil, let defaultValue = defaultValueIfFileIsMissing {
//            return defaultValue
//        }
//        let path = try validateFileExists(file)
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: path))
//            return try jsonDecoder.decode(T.self, from: data)
//        } catch {
//            Logger.error("Unable to read or decode file '\(path)': \(error)")
//            throw ArgumentsError.argumentValueCannotBeUsed(key, error)
//        }
//    }
//    
//    public static func scheduleStrategy(_ value: String?) throws -> ScheduleStrategyType {
//        let strategyRawType = try validateNotNil(value)
//        guard let scheduleStrategy = ScheduleStrategyType(rawValue: strategyRawType) else {
//            throw ArgumentsError.argumentValueCannotBeUsed(key, AdditionalArgumentValidationError.unknownScheduleStrategy(strategyRawType))
//        }
//        return scheduleStrategy
//    }
//    
//    public static func socketAddress(_ value: String?) throws -> SocketAddress {
//        let stringValue = try validateNotNil(value)
//        return try SocketAddress.from(string: stringValue)
//    }
//    
//    public static func validateNotNil<T>(_ value: T?) throws -> T {
//        guard let value = value else { throw ArgumentsError.argumentIsMissing(key) }
//        return value
//    }
//    
//    public static func validateResourceLocation(_ value: String?) throws -> ResourceLocation {
//        let string = try validateNotNil(value, key: key)
//        return try ResourceLocation.from(string)
//    }
//    
//    public static func validateResourceLocationOrNil(_ value: String?) throws -> ResourceLocation? {
//        guard let string = value else { return nil }
//        return try ResourceLocation.from(string)
//    }
//    
//    public static func validateResourceLocations(_ values: [String], key: ArgumentDescription) throws -> [ResourceLocation] {
//        return try values.map { value in
//            let string = try validateNotNil(value, key: key)
//            return try ResourceLocation.from(string)
//        }
//    }
//    
//    public static func validateFileExists(_ value: String?) throws -> String {
//        let path = try validateNotNil(value)
//        if !FileManager.default.fileExists(atPath: path) {
//            throw ArgumentsError.argumentValueCannotBeUsed(AdditionalArgumentValidationError.notFound(path))
//        }
//        return path
//    }
//    
//    public static func validateNilOrFileExists(_ value: String?, key: ArgumentDescription) throws -> String? {
//        guard value != nil else { return nil }
//        return try validateFileExists(value, key: key)
//    }
//    
//    public static func validateFilesExist(_ values: [String], key: ArgumentDescription) throws -> [String] {
//        return try values.map { try validateFileExists($0, key: key) }
//    }
}
