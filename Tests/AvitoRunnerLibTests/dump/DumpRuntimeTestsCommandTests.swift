import ArgLib
import AvitoRunnerLib
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import PathLib
import ResourceLocationResolver
import RuntimeDump
import SimulatorPoolTestHelpers
import TemporaryStuff
import XCTest

final class DumpRuntimeTestsCommandTests: XCTestCase {
    func test___correct_inputs___dumps_available_test_entries_to_file() throws {
        // given
        runtimeTestQuerierMock.result = runtimeQueryResult
        
        // when
        XCTAssertNoThrow(
            try command.run(
                payload: createCommandPayload()
            )
        )
        
        // then
        let dumpedData = try Data(contentsOf: outputPath.fileUrl)
        let dumpedContents = try JSONDecoder().decode([RuntimeTestEntry].self, from: dumpedData)
        XCTAssertEqual(
            dumpedContents,
            runtimeTestQuerierMock.result.availableRuntimeTests
        )
    }
    
    func test___missing_app_and_fbsimctl___works() throws {
        XCTAssertNoThrow(
            try command.run(
                payload: createCommandPayload(
                    argsToOmit: [
                        .app,
                        .fbsimctl
                    ]
                )
            )
        )
    }
    
    func test___missing_app_and_present_fbsimctl___works() throws {
        XCTAssertNoThrow(
            try command.run(
                payload: createCommandPayload(
                    argsToOmit: [
                        .app
                    ]
                )
            )
        )
    }
    
    func test___present_app_and_missing_fbsimctl___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(
                    argsToOmit: [
                        .fbsimctl
                    ]
                )
            )
        )
    }
    
    func test___when_xctestbundle_is_misssing___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(argsToOmit: [.xctestBundle])
            )
        )
    }
    
    func test___when_output_misssing___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(argsToOmit: [.output])
            )
        )
    }
    
    func test___when_fbxctest_misssing___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(argsToOmit: [.fbxctest])
            )
        )
    }
    
    func test___when_test_destinations_misssing___throws() throws {
        XCTAssertThrowsError(
            try command.run(
                payload: createCommandPayload(argsToOmit: [.testDestinations])
            )
        )
    }
    
    private func createCommandPayload(
        argsToOmit: Set<KnownArguments> = Set(),
        additions: Set<ArgumentValueHolder> = Set()
    ) -> CommandPayload {
        var valueHolders = Set<ArgumentValueHolder>()
        if !argsToOmit.contains(.app) {
            valueHolders.insert(argumentValue(.app, value: "http://example.com/app.zip"))
        }
        if !argsToOmit.contains(.fbsimctl) {
            valueHolders.insert(argumentValue(.fbsimctl, value: "http://example.com/fbsimctl.zip"))
        }
        if !argsToOmit.contains(.fbxctest) {
            valueHolders.insert(argumentValue(.fbxctest, value: "http://example.com/fbxctest.zip"))
        }
        if !argsToOmit.contains(.output) {
            valueHolders.insert(argumentValue(.output, value: outputPath.pathString))
        }
        if !argsToOmit.contains(.testDestinations) {
            XCTAssertNoThrow(
                valueHolders.insert(argumentValue(.testDestinations, value: try createTestDestinationConfiguration().pathString)),
                "Looks like test failed to create a file inside temp folder"
            )
        }
        if !argsToOmit.contains(.xctestBundle) {
            valueHolders.insert(argumentValue(.xctestBundle, value: "http://example.com/xctestBundle.zip"))
        }
        return CommandPayload(
            valueHolders: valueHolders.union(additions)
        )
    }
    
    private func createTestDestinationConfiguration() throws -> AbsolutePath {
        let testDestinationConfiguration = TestDestinationConfiguration(
            testDestination: TestDestinationFixtures.testDestination,
            reportOutput: ReportOutput(junit: nil, tracingReport: nil)
        )
        let data = try JSONEncoder().encode([testDestinationConfiguration])
        return try tempFolder.createFile(filename: "test_destinations.json", contents: data)
    }
    
    let tempFolder = try! TemporaryFolder()
    let resourceLocationResolver = ResourceLocationResolver()
    let runtimeTestQuerierMock = RuntimeTestQuerierMock()
    let runtimeQueryResult = RuntimeQueryResult(
        unavailableTestsToRun: [],
        availableRuntimeTests: [RuntimeTestEntry(className: "class", path: "path", testMethods: ["test1"], caseId: nil, tags: [])]
    )
    
    lazy var outputPath = tempFolder.pathWith(
        components: ["output.json"]
    )
    lazy var simulatorPool = OnDemandSimulatorPoolWithDefaultSimulatorControllerMock(
        resourceLocationResolver: resourceLocationResolver,
        tempFolder: tempFolder
    )
    lazy var command = DumpRuntimeTestsCommand(
        eventBus: EventBus(),
        resourceLocationResolver: resourceLocationResolver,
        runtimeTestQuerier: runtimeTestQuerierMock,
        tempFolder: tempFolder
    )
}

