import Foundation

public enum DumpCommandConfigurationError: Error, CustomStringConvertible {
    case bothAppAndFbsimctlRequired
    
    public var description: String {
        switch self {
        case .bothAppAndFbsimctlRequired:
            return "To use runtime dump with application test bundles, both --fbsimctl and --app arguments should be provided"
        }
    }
}
