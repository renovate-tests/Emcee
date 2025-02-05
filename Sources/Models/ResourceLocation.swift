import Foundation

/// A location of the resource.
public enum ResourceLocation: Hashable, CustomStringConvertible, Codable {
    /// direct path to the file on disk
    case localFilePath(String)
    
    /// URL to archive that should be extracted in order to get the file.
    /// Filename in this case can be specified by fragment:
    /// http://example.com/file.zip#actualFileInsideZip
    case remoteUrl(URL)
    
    public enum ValidationError: Error, CustomStringConvertible {
        case cannotCreateUrl(String)
        case fileDoesNotExist(String)
        
        public var description: String {
            switch self {
            case .cannotCreateUrl(let string):
                return "Attempt to create a URL from string '\(string)' failed"
            case .fileDoesNotExist(let path):
                return "File does not exist at path: '\(path)'"
            }
        }
    }
    
    public var url: URL? {
        switch self {
        case .remoteUrl(let url):
            return url
        case .localFilePath:
            return nil
        }
    }
    
    public static func from(_ string: String) throws -> ResourceLocation {
        let components = try urlComponents(string)
        guard let url = components.url else { throw ValidationError.cannotCreateUrl(string) }
        if url.isFileURL {
            return try withPathString(string)
        } else {
            return withUrl(url)
        }
    }
    
    private static let percentEncodedCharacters: CharacterSet = CharacterSet()
        .union(.urlQueryAllowed)
        .union(.urlHostAllowed)
        .union(.urlPathAllowed)
        .union(.urlUserAllowed)
        .union(.urlFragmentAllowed)
        .union(CharacterSet(charactersIn: "#"))
        .union(.urlPasswordAllowed)
    
    private static func urlComponents(_ string: String) throws -> URLComponents {
        let string = string.addingPercentEncoding(withAllowedCharacters: percentEncodedCharacters) ?? string
        guard var components = URLComponents(string: string) else { throw ValidationError.cannotCreateUrl(string) }
        if components.scheme == nil {
            components.scheme = "file"
        }
        return components
    }
    
    private static func withoutValueValidation(_ string: String) throws -> ResourceLocation {
        let components = try urlComponents(string)
        guard let url = components.url else { throw ValidationError.cannotCreateUrl(string) }
        if url.isFileURL {
            return .localFilePath(string)
        } else {
            return .remoteUrl(url)
        }
    }
    
    public static func from(_ strings: [String]) throws -> [ResourceLocation] {
        return try strings.map { try from($0) }
    }
    
    private static func withUrl(_ url: URL) -> ResourceLocation {
        return ResourceLocation.remoteUrl(url)
    }
    
    private static func withPathString(_ string: String) throws -> ResourceLocation {
        guard FileManager.default.fileExists(atPath: string) else { throw ValidationError.fileDoesNotExist(string) }
        return ResourceLocation.localFilePath(string)
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .localFilePath(let path):
            hasher.combine(path)
        case .remoteUrl(let url):
            hasher.combine(url)
        }
    }
    
    public var description: String {
        switch self {
        case .localFilePath(let path):
            return "<local path: \(path)>"
        case .remoteUrl(let url):
            return "<url: \(url)>"
        }
    }
    
    public var stringValue: String {
        switch self {
        case .localFilePath(let path):
            return path
        case .remoteUrl(let url):
            return url.absoluteString
        }
    }
    
    public static func == (left: ResourceLocation, right: ResourceLocation) -> Bool {
        switch (left, right) {
        case (.localFilePath(let leftPath), .localFilePath(let rightPath)):
            return leftPath == rightPath
        case (.remoteUrl(let leftUrl), .remoteUrl(let rightUrl)):
            return leftUrl == rightUrl
        default:
            return false
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = try ResourceLocation.withoutValueValidation(try container.decode(String.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
    
}
