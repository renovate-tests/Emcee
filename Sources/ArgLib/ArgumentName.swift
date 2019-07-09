import Foundation

public enum ArgumentName: Hashable, ExpressibleByStringLiteral {
    /// Represents a dashed arg. For dashless name "arg" the argument is "--arg".
    case dashed(dashlessName: String)
    
    var expectedInputValue: String {
        switch self {
        case .dashed(let dashlessName):
            return "--\(dashlessName)"
        }
    }
    
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self = .dashed(dashlessName: value)
    }
}
