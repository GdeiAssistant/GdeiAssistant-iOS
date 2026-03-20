import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var showReloadHint = false

    private let environment: AppEnvironment
    private let preferences: UserPreferences

    init(environment: AppEnvironment, preferences: UserPreferences) {
        self.environment = environment
        self.preferences = preferences
    }

    var isDebug: Bool {
        environment.isDebug
    }

    var modeDisplayText: String {
        environment.dataSourceMode.displayName
    }

    var baseURLText: String {
        environment.baseURL.absoluteString
    }

    var networkEnvironmentText: String {
        environment.networkEnvironment.displayName
    }

    var clientTypeText: String {
        environment.clientType
    }

    var useMockData: Bool {
        environment.dataSourceMode == .mock
    }

    var selectedNetworkEnvironment: NetworkEnvironment {
        environment.networkEnvironment
    }

    func updateMockEnabled(_ isEnabled: Bool) {
        guard environment.isDebug else { return }

        preferences.setUseMockData(isEnabled)
        environment.updateDataSourceMode(isEnabled ? .mock : .remote)
        showReloadHint = true
    }

    func updateNetworkEnvironment(_ environment: NetworkEnvironment) {
        guard self.environment.isDebug else { return }

        preferences.setNetworkEnvironment(environment)
        self.environment.updateNetworkEnvironment(environment)
        showReloadHint = true
    }
}
