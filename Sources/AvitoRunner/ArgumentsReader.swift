import Foundation
import Logging
import Models

final class ArgumentsReader {
    private init() {}
    
    public static func environment(file: String?, key: ArgumentDescription) throws -> [String: String] {
        guard let environmentFile = try validateNilOrFileExists(file, key: key) else { return [:] }
        do {
            let environmentData = try Data(contentsOf: URL(fileURLWithPath: environmentFile))
            return try JSONDecoder().decode([String: String].self, from: environmentData)
        } catch {
            log("Unable to read or decode environments file: \(error)", color: .red)
            throw ArgumentsError.argumentValueCannotBeUsed(key, error)
        }
    }
    
    public static func testDestinations(_ file: String?, key: ArgumentDescription) throws -> [TestDestinationConfiguration] {
        let testDestinationFile = try validateFileExists(file, key: key)
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testDestinationFile))
            return try JSONDecoder().decode([TestDestinationConfiguration].self, from: data)
        } catch {
            log("Unable to read or decode test destinations file: \(error)", color: .red)
            throw ArgumentsError.argumentValueCannotBeUsed(key, error)
        }
    }
    
    public static func scheduleStrategy(_ value: String?, key: ArgumentDescription) throws -> ScheduleStrategyType {
        let strategyRawType = try validateNotNil(value, key: key)
        guard let scheduleStrategy = ScheduleStrategyType(rawValue: strategyRawType) else {
            throw ArgumentsError.argumentValueCannotBeUsed(
                KnownStringArguments.scheduleStrategy,
                AdditionalArgumentValidationError.unknownScheduleStrategy(strategyRawType))
        }
        return scheduleStrategy
    }
    
    public static func validateNotNil<T>(_ value: T?, key: ArgumentDescription) throws -> T {
        guard let value = value else { throw ArgumentsError.argumentIsMissing(key) }
        return value
    }
    
    public static func validateFileExists(_ value: String?, key: ArgumentDescription) throws -> String {
        let path = try validateNotNil(value, key: key)
        if !FileManager.default.fileExists(atPath: path) {
            throw ArgumentsError.argumentValueCannotBeUsed(key, AdditionalArgumentValidationError.notFound(path))
        }
        return path
    }
    
    public static func validateNilOrFileExists(_ value: String?, key: ArgumentDescription) throws -> String? {
        guard value != nil else { return nil }
        return try validateFileExists(value, key: key)
    }
    
    public static func validateFilesExist(_ values: [String], key: ArgumentDescription) throws -> [String] {
        for value in values {
            _ = try validateFileExists(value, key: key)
        }
        return values
    }
}
