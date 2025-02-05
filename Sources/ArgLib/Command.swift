import Foundation

public protocol Command {
    var name: String { get }
    var description: String { get }
    var arguments: Arguments { get }
    
    func run(valueHolders: Set<ArgumentValueHolder>) throws
}
