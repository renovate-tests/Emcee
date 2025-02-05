import EventBus
import Foundation
import Models
import ResourceLocationResolver

public final class EventBusFactory {
    private init() {}
    
    public static func createEventBusWithAttachedPluginManager(
        pluginLocations: [PluginLocation],
        resourceLocationResolver: ResourceLocationResolver)
        throws -> EventBus
    {
        let eventBus = EventBus()
        try startPluginManager(
            eventBus: eventBus,
            pluginLocations: pluginLocations,
            resourceLocationResolver: resourceLocationResolver
        )
        return eventBus
    }
    
    private static func startPluginManager(
        eventBus: EventBus,
        pluginLocations: [PluginLocation],
        resourceLocationResolver: ResourceLocationResolver)
        throws
    {
        let pluginManager = PluginManager(
            pluginLocations: pluginLocations,
            resourceLocationResolver: resourceLocationResolver
        )
        try pluginManager.startPlugins()
        eventBus.add(stream: pluginManager)
    }
}
