import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testUpdateNetworkEnvironmentPersistsPreferenceAndUpdatesBaseURLInDebug() {
        let defaults = makeDefaults(testName: #function)
        let preferences = UserPreferences(defaults: defaults)
        let environment = AppEnvironment(
            networkEnvironment: .staging,
            dataSourceMode: .remote,
            isDebug: true,
            clientType: "IOS"
        )
        let viewModel = SettingsViewModel(environment: environment, preferences: preferences)
        TestLifetimeRetainer.retain(viewModel)

        viewModel.updateNetworkEnvironment(.dev)

        XCTAssertEqual(environment.networkEnvironment, .dev)
        XCTAssertEqual(environment.baseURL, NetworkEnvironment.dev.baseURL)
        XCTAssertEqual(preferences.currentNetworkEnvironment, .dev)
        XCTAssertTrue(viewModel.showReloadHint)
    }

    func testUpdateNetworkEnvironmentIsIgnoredOutsideDebugBuilds() {
        let defaults = makeDefaults(testName: #function)
        let preferences = UserPreferences(defaults: defaults)
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        let viewModel = SettingsViewModel(environment: environment, preferences: preferences)
        TestLifetimeRetainer.retain(viewModel)

        viewModel.updateNetworkEnvironment(.dev)

        XCTAssertEqual(environment.networkEnvironment, .prod)
        XCTAssertEqual(environment.baseURL, NetworkEnvironment.prod.baseURL)
        XCTAssertEqual(preferences.currentNetworkEnvironment, .prod)
        XCTAssertFalse(viewModel.showReloadHint)
    }

    func testUpdateMockEnabledSwitchesEnvironmentModeInDebug() {
        let defaults = makeDefaults(testName: #function)
        let preferences = UserPreferences(defaults: defaults)
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: true,
            clientType: "IOS"
        )
        let viewModel = SettingsViewModel(environment: environment, preferences: preferences)
        TestLifetimeRetainer.retain(viewModel)

        viewModel.updateMockEnabled(true)

        XCTAssertEqual(environment.dataSourceMode, .mock)
        XCTAssertEqual(preferences.currentDataSourceMode, .mock)
        XCTAssertTrue(viewModel.showReloadHint)
    }

    private func makeDefaults(testName: String) -> UserDefaults {
        let suiteName = "SettingsViewModelTests.\(testName)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
