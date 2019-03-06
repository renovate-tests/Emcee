import Foundation

public enum RunnerBinaryLocation: Hashable, Codable, CustomStringConvertible {
    private static let xcodebuildPath = "/usr/bin/xcodebuild"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let resourceLocation = try container.decode(ResourceLocation.self)
        if resourceLocation.stringValue == RunnerBinaryLocation.xcodebuildPath {
            self = .xcodebuild
        } else {
            self = .fbxctest(FbxctestLocation(resourceLocation))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(resourceLocation)
    }

    case fbxctest(FbxctestLocation)
    case xcodebuild

    public var description: String {
        switch self {
        case .fbxctest(let fbxctestLocation):
            return "\(fbxctestLocation)"
        case .xcodebuild:
            return "xcodebuild"
        }
    }

    public var resourceLocation: ResourceLocation {
        switch self {
        case .fbxctest(let fbxctestLocation):
            return fbxctestLocation.resourceLocation
        case .xcodebuild:
            return ResourceLocation.localFilePath(RunnerBinaryLocation.xcodebuildPath)
        }
    }
}
