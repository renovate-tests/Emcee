import json
import os
from xml.etree import ElementTree

from IntegrationTests.helpers.fixture_types.AvitoRunnerArgs import AvitoRunnerArgs
from IntegrationTests.helpers.fixture_types.EmceePluginFixture import EmceePluginFixture
from IntegrationTests.helpers.fixture_types.IosAppFixture import IosAppFixture
from IntegrationTests.helpers.common_fixtures import *


def check_file_exists(path):
    if not os.path.exists(path):
        raise AssertionError("Expected to have file at: {path}".format(path=path))


def get_test_cases_from_xml_file(path):
    tree = ElementTree.parse(path)
    root = tree.getroot()
    cases = []
    for case in root.findall('.//testcase'):
        if not case.findall('skipped'):
            case_dict = case.attrib.copy()
            if len(case):
                for child in case:
                    print("child: " + str(child))
                    case_dict[child.tag] = child.attrib.copy()
            cases.append(case_dict)
    return cases


class TestApplicationSmokeTests:
    def test_junit_contents(self, smoke_apptests_result: AvitoRunnerArgs):
        iphone_se_junit = get_test_cases_from_xml_file(
            path=smoke_apptests_result.current_directory.sub_path(
                'auxiliary/tempfolder/test-results/iphone_se_ios_103.xml')
        )
        assert len(iphone_se_junit) == 2

        successful_tests = set([item["name"] for item in iphone_se_junit if item.get("failure") is None])
        expected_successful_tests = {
            "testApplicationTest___successful",
        }
        failed_tests = set([item["name"] for item in iphone_se_junit if item.get("failure") is not None])
        expected_failed_tests = {
            "testApplicationTest___failing",
        }

        assert successful_tests == expected_successful_tests
        assert failed_tests == expected_failed_tests



class TestSmokeTests:
    def test_check_reports_exist(self, smoke_uitests_result: AvitoRunnerArgs):
        check_file_exists(
            smoke_uitests_result.current_directory.sub_path('auxiliary/tempfolder/test-results/iphone_se_ios_103.json'))
        check_file_exists(
            smoke_uitests_result.current_directory.sub_path('auxiliary/tempfolder/test-results/iphone_se_ios_103.xml'))
        check_file_exists(smoke_uitests_result.trace_path)
        check_file_exists(smoke_uitests_result.junit_path)

    def test_junit_contents(self, smoke_uitests_result: AvitoRunnerArgs):
        iphone_se_junit = get_test_cases_from_xml_file(
            path=smoke_uitests_result.current_directory.sub_path(
                'auxiliary/tempfolder/test-results/iphone_se_ios_103.xml')
        )
        assert len(iphone_se_junit) == 6

        successful_tests = set([item["name"] for item in iphone_se_junit if item.get("failure") is None])
        expected_successful_tests = {
            "testSlowTest",
            "testAlwaysSuccess",
            "testQuickTest",
            "testWritingToTestWorkingDir"
        }
        failed_tests = set([item["name"] for item in iphone_se_junit if item.get("failure") is not None])
        expected_failed_tests = {
            "testAlwaysFails",
            "testMethodThatThrowsSwiftError"
        }

        assert successful_tests == expected_successful_tests
        assert failed_tests == expected_failed_tests

    def test_plugin_output(self, smoke_uitests_result: AvitoRunnerArgs):
        output_path = open(os.path.join(smoke_uitests_result.plugins[0].path, 'output.json'), 'r')
        json_contents = json.load(output_path)

        tear_down_events = []
        runner_events = []
        unknown_events = []

        for event in json_contents:
            if event["eventType"] == "runnerEvent":
                runner_events.append(event)
            elif event["eventType"] == "tearDown":
                tear_down_events.append(event)
            else:
                unknown_events.append(event)

        self.check_runner_events(runner_events)
        self.check_tear_down_events(tear_down_events)
        self.check_unknown_events(unknown_events)

    def check_runner_events(self, events):
        all_runner_events = [event["runnerEvent"] for event in events]
        all_events_envs = [event["testContext"]["environment"] for event in all_runner_events]

        working_directory_values = [event_env.get("EMCEE_TESTS_WORKING_DIRECTORY") for event_env in all_events_envs]
        "Check that env.EMCEE_TESTS_WORKING_DIRECTORY is set"

        for working_dir in working_directory_values:
            assert working_dir != None

        all_will_run_events = [event for event in all_runner_events if event["eventType"] == "willRun"]
        all_did_run_events = [event for event in all_runner_events if event["eventType"] == "didRun"]
        "Check that number of willRun events equal to didRun events"
        assert len(all_will_run_events) == len(all_did_run_events)

        all_will_run_tests = [test_entry["testName"]["methodName"]
                              for event in all_will_run_events
                              for test_entry in event["testEntries"]]
        all_did_run_tests = [test_entry_result["testEntry"]["testName"]["methodName"]
                             for event in all_did_run_events
                             for test_entry_result in event["results"]]
        "Check that willRun events and didRun events match the test method names"
        assert sorted(all_will_run_tests) == sorted(all_did_run_tests)

        all_test_expected_to_be_ran = [
            "fakeTest",
            "testAlwaysSuccess",
            "testWritingToTestWorkingDir",
            "testSlowTest",
            "testQuickTest",
            "testAlwaysFails",
            "testMethodThatThrowsSwiftError"
        ]
        "Check that all expected tests have been invoked, including the fakeTest which is used for runtime dump feature"

        assert set(all_will_run_tests) == set(all_test_expected_to_be_ran)

        self.check_that_testWritingToTestWorkingDir_writes_to_working_dir(all_runner_events)

    def check_that_testWritingToTestWorkingDir_writes_to_working_dir(self, all_runner_events):
        did_run_events = [event for event in all_runner_events if event["eventType"] == "didRun"]
        event = [event
                 for event in did_run_events
                 for test_entry_result in event["results"]
                 if test_entry_result["testEntry"]["testName"]["methodName"] == "testWritingToTestWorkingDir"][0]
        expected_path = os.path.join(
            event["testContext"]["environment"]["EMCEE_TESTS_WORKING_DIRECTORY"],
            "test_artifact.txt")
        test_output_file = open(expected_path, "r")
        contents = test_output_file.read()

        assert contents == "contents"

    def check_tear_down_events(self, events):
        assert len(events) == 1

    def check_unknown_events(self, events):
        assert len(events) == 0


@pytest.fixture(scope="session")
def smoke_uitests_result(
        request,
        repo_root: Directory,
        avito_runner: ExecutableFixture,
        smoke_tests_app: IosAppFixture,
        smoke_tests_plugin: EmceePluginFixture,
        fbsimctl_url: str,
        fbxctest_url: str,
        ui_tests_arg_file: str,
):
    def make():
        print("Running integration tests")

        temporary_directory = Directory.make_temporary(remove_automatically=False)

        test_results_directory = temporary_directory.make_sub_directory("test_results")
        current_directory = temporary_directory.make_sub_directory("current_directory")
        modified_arg_file_path = modify_arg_file(ui_tests_arg_file, temporary_directory, smoke_tests_app, True)

        args = AvitoRunnerArgs(
            avito_runner=avito_runner,
            fbsimctl_url=fbsimctl_url,
            fbxctest_url=fbxctest_url,
            junit_path=test_results_directory.sub_path('junit.combined.xml'),
            trace_path=test_results_directory.sub_path('trace.combined.json'),
            test_destinations=[repo_root.sub_path('auxiliary/destination_iphone_se_ios103.json')],
            temp_folder=temporary_directory.make_sub_directory("temp_folder").path,
            current_directory=current_directory,
            number_of_simulators=2,
            plugins=[smoke_tests_plugin],
            schedule_strategy='individual',
            single_test_timeout=100,
            test_arg_file_path=modified_arg_file_path
        )

        bash(command=args.command(), current_directory=current_directory.path)

        yield args

    yield from using_pycache(
        request=request,
        key="smoke_uitests_result",
        make=make
    )


@pytest.fixture(scope="session")
def smoke_apptests_result(
        request,
        repo_root: Directory,
        avito_runner: ExecutableFixture,
        smoke_tests_app: IosAppFixture,
        smoke_tests_plugin: EmceePluginFixture,
        fbsimctl_url: str,
        fbxctest_url: str,
        app_tests_arg_file: str,
):
    def make():
        print("Running integration tests")

        temporary_directory = Directory.make_temporary(remove_automatically=False)

        test_results_directory = temporary_directory.make_sub_directory("test_results")
        current_directory = temporary_directory.make_sub_directory("current_directory")
        modified_arg_file_path = modify_arg_file(app_tests_arg_file, temporary_directory, smoke_tests_app, False)

        args = AvitoRunnerArgs(
            avito_runner=avito_runner,
            fbsimctl_url=fbsimctl_url,
            fbxctest_url=fbxctest_url,
            junit_path=test_results_directory.sub_path('junit.combined.xml'),
            trace_path=test_results_directory.sub_path('trace.combined.json'),
            test_destinations=[repo_root.sub_path('auxiliary/destination_iphone_se_ios103.json')],
            temp_folder=temporary_directory.make_sub_directory("temp_folder").path,
            current_directory=current_directory,
            number_of_simulators=1,
            plugins=[smoke_tests_plugin],
            schedule_strategy='individual',
            single_test_timeout=20,
            test_arg_file_path=modified_arg_file_path
        )

        bash(command=args.command(), current_directory=current_directory.path)

        yield args

    yield from using_pycache(
        request=request,
        key="smoke_apptests_result",
        make=make
    )


def modify_arg_file(
        app_tests_arg_file_path: str,
        temporary_directory: Directory,
        ios_app_fixture: IosAppFixture,
        running_ui_tests: bool
) -> str:
    arg_file_json = open(app_tests_arg_file_path, 'r')
    arg_file = json.load(arg_file_json)
    test_bundle = ios_app_fixture.ui_xctest_bundle_path if running_ui_tests else ios_app_fixture.app_xctest_bundle_path

    build_artifacts_json = {
        "appBundle": f"{ios_app_fixture.app_path}",
        "runner": f"{ios_app_fixture.ui_tests_runner_path}",
        "xcTestBundle": f"{test_bundle}",
        "additionalApplicationBundles": []
    }

    for index, entry in enumerate(arg_file["entries"]):
        arg_file["entries"][index]["buildArtifacts"] = build_artifacts_json

    modified_arg_file_path_suffix = "ui_tests" if running_ui_tests else "app_tests"
    modified_arg_file_path = temporary_directory.sub_path(f'modified_arg_file_path_{modified_arg_file_path_suffix}.json')
    modified_arg_file = open(modified_arg_file_path, "w+")
    json.dump(arg_file, modified_arg_file)
    return modified_arg_file_path


@pytest.fixture(scope="session")
def smoke_tests_app(request, repo_root):
    def make():
        temporary_directory: Directory = Directory.make_temporary(remove_automatically=False)
        derived_data: Directory = temporary_directory.make_sub_directory(path="DerivedData")
        xcodebuild_log_path: str = derived_data.sub_path('xcodebuild.log.ignored')

        print(f'Building for testing. Build is log path: {xcodebuild_log_path}')

        bash(command=f'''
        set -o pipefail && \
        cd "{repo_root.path}/TestApp" && xcodebuild build-for-testing \
        -scheme "TestApp" \
        -derivedDataPath {derived_data.path} \
        -destination "platform=iOS Simulator,name=iPhone SE,OS=10.3.1" \
        | tee "{xcodebuild_log_path}" || (echo "Failed! Logs: `cat {xcodebuild_log_path}`" && exit 3)
        ''')

        # Work around a bug when xcodebuild puts Build and Indexes folders to a pwd instead of derived data
        def derived_data_workaround(top_level_folder: str):
            build_folder = '{repo_root.path}/TestApp/{top_level_folder}'
            if os.path.isdir(build_folder):
                print(
                    f'Unexpectidly found {top_level_folder} in PWD, moving {repo_root.path}/TestApp/{top_level_folder}/ to {derived_data.path}/')
                os.rename(build_folder, f'{derived_data.path}/{top_level_folder}')

        derived_data_workaround(top_level_folder='Build')
        derived_data_workaround(top_level_folder='Index')

        yield IosAppFixture(
            app_path=f'{derived_data.path}/Build/Products/Debug-iphonesimulator/TestApp.app',
            ui_tests_runner_path=f'{derived_data.path}/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app',
            ui_xctest_bundle_path=f'{derived_data.path}/Build/Products/Debug-iphonesimulator/TestAppUITests-Runner.app/PlugIns/TestAppUITests.xctest',
            app_xctest_bundle_path=f'{derived_data.path}/Build/Products/Debug-iphonesimulator/TestApp.app/PlugIns/TestAppTests.xctest'
        )

    yield from using_pycache(
        request=request,
        key="smoke_tests_app",
        make=make
    )


@pytest.fixture(scope="session")
def smoke_tests_plugin(request, repo_root):
    def make():
        bash(command='make build', current_directory=f'{repo_root.path}/TestPlugin')

        yield EmceePluginFixture(
            path=f'{repo_root.path}/TestPlugin/.build/debug/TestPlugin.emceeplugin'
        )

    yield from using_pycache(
        request=request,
        key="smoke_tests_plugin",
        make=make
    )
