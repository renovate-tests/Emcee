import ArgLib
import AvitoRunnerLib
import Foundation
import Models
import PathLib
import ResourceLocationResolver
import TemporaryStuff
import XCTest

final class DistWorkCommandTests: XCTestCase {
    func test___correct_inputs___propagates_args_to_dist_worker() {
        XCTAssertNoThrow(
            try command.run(
                payload: createCommandPayload()
            )
        )
        
        XCTAssertEqual(fakeDistWorkProvider.allCreatedDistWorkers.count, 1)
        guard let createdDistWorker = fakeDistWorkProvider.allCreatedDistWorkers.first else {
            return XCTFail("Expected to create a single dist worker")
        }
        
        XCTAssertEqual(
            createdDistWorker.queueServerAddress,
            try SocketAddress.from(string: fakeQueueHostPort)
        )
        XCTAssertEqual(
            ObjectIdentifier(createdDistWorker.resourceLocationResolver),
            ObjectIdentifier(resourceLocationResolver)
        )
        XCTAssertEqual(
            createdDistWorker.workerId,
            WorkerId(value: fakeWorkerId)
        )
    }
    
    func test___missing_analytics_сonfiguration___works() throws {
        XCTAssertNoThrow(
            try command.run(
                payload: createCommandPayload(
                    argsToOmit: [
                        .analyticsConfiguration
                    ]
                )
            )
        )
    }
    
    func test___missing_queue_server___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(
                    argsToOmit: [
                        .queueServer
                    ]
                )
            )
        )
    }
    
    func test___missing_worker_id___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(
                    argsToOmit: [
                        .workerId
                    ]
                )
            )
        )
    }
    
    private func createCommandPayload(
        argsToOmit: Set<KnownArguments> = Set()
    ) -> CommandPayload {
        var valueHolders = Set<ArgumentValueHolder>()
        
        if !argsToOmit.contains(.analyticsConfiguration) {
            XCTAssertNoThrow(
                valueHolders.insert(argumentValue(.analyticsConfiguration, value: try createAnalyticsConfiguration().pathString)),
                "Looks like test failed to create a file in temporary folder"
            )
        }
        if !argsToOmit.contains(.queueServer) {
            valueHolders.insert(argumentValue(.queueServer, value: fakeQueueHostPort))
        }
        if !argsToOmit.contains(.workerId) {
            valueHolders.insert(argumentValue(.workerId, value: fakeWorkerId))
        }
        
        return CommandPayload(valueHolders: valueHolders)
    }
    
    private func createAnalyticsConfiguration() throws -> AbsolutePath {
        let config = AnalyticsConfiguration(
            graphiteConfiguration: GraphiteConfiguration(
                socketAddress: try SocketAddress.from(string: fakeGraphiteAddress),
                metricPrefix: "pre.fix"
            ),
            sentryConfiguration: nil
        )
        let data = try JSONEncoder().encode(config)
        return try tempFolder.createFile(filename: "analytics_config.json", contents: data)
    }
    
    let fakeDistWorkProvider = FakeDistWorkerProvider()
    let fakeQueueHostPort = "server:1234"
    let fakeWorkerId = "worker_id"
    let fakeGraphiteAddress = "graph1te_921083901283092:65432"
    let resourceLocationResolver = ResourceLocationResolver()
    let tempFolder = try! TemporaryFolder()
    
    lazy var command = DistWorkCommand(
        distWorkerProvider: fakeDistWorkProvider,
        resourceLocationResolver: resourceLocationResolver
    )
}

