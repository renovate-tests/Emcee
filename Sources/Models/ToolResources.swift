import Foundation

public final class ToolResources: Codable, Hashable, CustomStringConvertible {
    /// Location of fbsimctl tool.
    public let fbsimctl: FbsimctlLocation
    
    /// Location of runner tool.
    public let runnerBinaryLocation: RunnerBinaryLocation
    
    public init(fbsimctl: FbsimctlLocation, runnerBinaryLocation: RunnerBinaryLocation) {
        self.fbsimctl = fbsimctl
        self.runnerBinaryLocation = runnerBinaryLocation
    }
    
    public static func == (left: ToolResources, right: ToolResources) -> Bool {
        return left.fbsimctl == right.fbsimctl
            && left.runnerBinaryLocation == right.runnerBinaryLocation
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fbsimctl)
        hasher.combine(runnerBinaryLocation)
    }
    
    public var description: String {
        return "<\((type(of: self))), \(fbsimctl), \(runnerBinaryLocation)>"
    }
}
