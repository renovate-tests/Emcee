import Dispatch
import EventBus
import Foundation
import JSONStream
import Logging
import LoggingSetup
import Models
import SynchronousWaiter

/// Allows the plugin to track `PluginEvent`s from the main process using the provided `EventBus`.
public final class Plugin {
    private let eventBus: EventBus
    private let jsonReaderQueue = DispatchQueue(label: "ru.avito.Plugin.jsonReaderQueue")
    private let stdinReadQueue = DispatchQueue(label: "ru.avito.Plugin.stdinReadQueue")
    private let jsonInputStream = BlockingArrayBasedJSONStream()
    private let jsonStreamToEventBusAdapter: JSONStreamToEventBusAdapter
    private var jsonStreamHasFinished = false
    private let eventReceiver: EventReceiver
    
    /// Creates a Plugin class that can be used to broadcast the PluginEvents from the main process
    /// into the provided EventBus.
    /// - Parameters:
    ///     - eventBus:             The event bus which will receive the events from the main process
    public init(eventBus: EventBus) throws {
        try LoggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        
        self.eventBus = eventBus
        self.jsonStreamToEventBusAdapter = JSONStreamToEventBusAdapter(eventBus: eventBus)
        self.eventReceiver = EventReceiver(
            address: try PluginSupport.pluginSocket(),
            pluginIdentifier: try PluginSupport.pluginIdentifier())
    }
    
    public func streamPluginEvents() {
        automaticallyInterruptOnTearDown()
        parseJsonStream()
        readDataInBackground()
    }
    
    public func join() {
        try? SynchronousWaiter.waitWhile {
            return jsonStreamHasFinished == false
        }
        LoggingSetup.tearDown()
    }
    
    private func automaticallyInterruptOnTearDown() {
        let tearDownHandler = TearDownHandler { [weak self] in
            self?.interrupt()
        }
        eventBus.add(stream: tearDownHandler)
    }
    
    private func parseJsonStream() {
        let jsonReader = JSONReader(inputStream: jsonInputStream, eventStream: jsonStreamToEventBusAdapter)
        jsonReaderQueue.async {
            do {
                Logger.verboseDebug("Starting JSON stream parser")
                try jsonReader.start()
            } catch {
                self.jsonStreamHasFinished = true
                Logger.error("JSON stream error: \(error)")
            }
            Logger.verboseDebug("JSON stream parser finished")
        }
    }
    
    private func interrupt() {
        eventBus.uponDeliveryOfAllEvents {
            self.eventReceiver.stop()
            self.jsonInputStream.willProvideMoreData = false
            self.jsonStreamHasFinished = true
        }
    }
    
    private func readDataInBackground() {
        eventReceiver.onData = { data in
            self.onNewData(data: data)
        }
        
        eventReceiver.onError = { error in
            Logger.error("\(error)")
            self.onEndOfData()
        }
        
        eventReceiver.onDisconnect = {
            self.onEndOfData()
        }
        
        eventReceiver.start()
    }
    
    private func onNewData(data: Data) {
        jsonInputStream.append(data)
    }
    
    private func onEndOfData() {
        jsonInputStream.willProvideMoreData = false
    }
}
