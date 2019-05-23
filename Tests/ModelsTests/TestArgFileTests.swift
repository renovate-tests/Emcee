import Foundation
import Models
import XCTest
import ModelsTestHelpers

final class TestArgFileTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: ["value": "key"],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }

    func test___decoding_full_json___fallback_xcTestBundle() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: ["value": "key"],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                buildArtifacts: buildArtifacts(runtimeDumpKind: .logicTest)
            )
        )
    }

    func test___decoding_without_environment_fallback_xcTestBundle() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": "/xcTestBundle",
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"]
                }
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts(runtimeDumpKind: .logicTest)
            )
        )
    }

    func test___decoding_without_environment() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"]
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }
    
    func test___decoding_with_test_type() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "testType": "logicTest",
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                }
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .logicTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }
    
    func test___decoding_with_environment() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": ["/additionalApp1", "/additionalApp2"],
                    "needHostAppToDumpTests": true
                }
            }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)
        
        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: ["value": "key"],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts()
            )
        )
    }

    func test___decoding_without_runner_additionalApplicationBundles_and_app() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "environment": {"value": "key"},
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "needHostAppToDumpTests": true
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: ["value": "key"],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts(appBundle: nil, runner: nil, additionalApplicationBundles: [])
            )
        )
    }

    func test___decoding_with_empty_additionalApplicationBundles() throws {
        let json = """
            {
                "testToRun": "ClassName/testMethod",
                "numberOfRetries": 42,
                "testDestination": {"deviceType": "iPhone SE", "runtime": "11.3"},
                "buildArtifacts": {
                    "appBundle": "/appBundle",
                    "runner": "/runner",
                    "xcTestBundle": {
                        "location": "/xcTestBundle",
                        "runtimeDumpKind": "appTest"
                    },
                    "additionalApplicationBundles": [],
                    "needHostAppToDumpTests": true
                }
            }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TestArgFile.Entry.self, from: json)

        XCTAssertEqual(
            entry,
            TestArgFile.Entry(
                testToRun: TestToRun.testName(TestName(className: "ClassName", methodName: "testMethod")),
                environment: [:],
                numberOfRetries: 42,
                testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "11.3"),
                testType: .uiTest,
                buildArtifacts: buildArtifacts(additionalApplicationBundles: [])
            )
        )
    }

    private func buildArtifacts(
        appBundle: String? = "/appBundle",
        runner: String? = "/runner",
        additionalApplicationBundles: [String] = ["/additionalApp1", "/additionalApp2"],
        runtimeDumpKind: RuntimeDumpKind = .appTest
    ) -> BuildArtifacts {
        return BuildArtifactsFixtures.withLocalPaths(
            appBundle: appBundle,
            runner: runner,
            xcTestBundle: "/xcTestBundle",
            additionalApplicationBundles: additionalApplicationBundles,
            runtimeDumpKind: runtimeDumpKind
        )
    }
}

