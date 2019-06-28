import Dispatch
import Extensions
import Foundation
import Logging
import Models
import OrderedSet
import ResourceLocationResolver
import TempFolder

/**
 * Every 'borrow' must have a corresponding 'free' call, otherwise the next borrow will throw an error.
 * There is no blocking mechanisms, the assumption is that the callers will use up to numberOfSimulators of threads
 * to borrow and free the simulators.
 */
public class SimulatorPool<T>: CustomStringConvertible where T: SimulatorController {
    private let numberOfSimulators: UInt
    private let testDestination: TestDestination
    private var controllers: OrderedSet<T>
    private var automaticCleanupWorkItem: DispatchWorkItem?
    private let automaticCleanupTiumeout: TimeInterval
    private let syncQueue = DispatchQueue(label: "ru.avito.SimulatorPool")
    private let cleanUpQueue = DispatchQueue(label: "ru.avito.SimulatorPool.cleanup")
    
    public var description: String {
        return "<\(type(of: self)): \(numberOfSimulators)-sim '\(testDestination.deviceType)'+'\(testDestination.runtime)'>"
    }
    
    public init(
        numberOfSimulators: UInt,
        testDestination: TestDestination,
        fbsimctl: ResolvableResourceLocation,
        tempFolder: TemporaryFolder,
        automaticCleanupTiumeout: TimeInterval = 10) throws
    {
        self.numberOfSimulators = numberOfSimulators
        self.testDestination = testDestination
        self.automaticCleanupTiumeout = automaticCleanupTiumeout
        controllers = try SimulatorPool.createControllers(
            count: numberOfSimulators,
            testDestination: testDestination,
            fbsimctl: fbsimctl,
            tempFolder: tempFolder)
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func allocateSimulatorController() throws -> T {
        return try syncQueue.sync {
            guard let simulator = controllers.removeLast() else {
                throw BorrowError.noSimulatorsLeft
            }
            Logger.verboseDebug("Allocated simulator: \(simulator)")
            cancelAutomaticCleanup()
            return simulator
        }
    }
    
    public func freeSimulatorController(_ simulator: T) {
        syncQueue.sync {
            controllers.append(simulator)
            Logger.verboseDebug("Freed simulator: \(simulator)")
            scheduleAutomaticCleanup()
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            cancelAutomaticCleanup()
            Logger.verboseDebug("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.deleteSimulator()
                } catch {
                    Logger.warning("Failed to delete simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
    
    public func shutdownSimulators() {
        syncQueue.sync {
            cancelAutomaticCleanup()
            Logger.verboseDebug("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.shutdownSimulator()
                } catch {
                    Logger.warning("Failed to shutdown simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
    
    private static func createControllers(
        count: UInt,
        testDestination: TestDestination,
        fbsimctl: ResolvableResourceLocation,
        tempFolder: TemporaryFolder
    ) throws -> OrderedSet<T> {
        var result = OrderedSet<T>()
        for index in 0 ..< count {
            let folderName = "sim_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.runtime)_\(index)"
            let workingDirectory = try tempFolder.pathByCreatingDirectories(components: [folderName])
            let simulator = Simulator(index: index, testDestination: testDestination, workingDirectory: workingDirectory)
            let controller = T(simulator: simulator, fbsimctl: fbsimctl)
            result.append(controller)
        }
        return result
    }
    
    private func cancelAutomaticCleanup() {
        automaticCleanupWorkItem?.cancel()
        automaticCleanupWorkItem = nil
    }
    
    private func scheduleAutomaticCleanup() {
        cancelAutomaticCleanup()
        
        let cancellationWorkItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.automaticCleanupWorkItem = nil
            if strongSelf.controllers.count == strongSelf.numberOfSimulators {
                Logger.debug("Simulator controllers were not in use for \(strongSelf.automaticCleanupTiumeout) seconds.")
                strongSelf.shutdownSimulators()
            }
        }
        cleanUpQueue.asyncAfter(deadline: .now() + automaticCleanupTiumeout, execute: cancellationWorkItem)
        self.automaticCleanupWorkItem = cancellationWorkItem
    }
}

private extension OrderedSet {
    mutating func removeLast() -> T? {
        guard let objectToRemove = last else {
            return nil
        }
        remove(objectToRemove)
        return objectToRemove
    }
}
