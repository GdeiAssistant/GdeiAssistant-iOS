import Foundation
import Combine

@MainActor
final class UserPreferences: ObservableObject {
    @Published var useMockData: Bool {
        didSet { persistUseMockDataIfNeeded() }
    }

    private let defaults: UserDefaults
    private var hasInitialized = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedUseMockData = defaults.object(forKey: AppConstants.UserDefaultsKeys.useMockData) as? Bool {
            self.useMockData = storedUseMockData
        } else {
            self.useMockData = _isDebugAssertConfiguration()
        }
        hasInitialized = true
    }

    var currentDataSourceMode: DataSourceMode {
        useMockData ? .mock : .remote
    }

    func setUseMockData(_ isEnabled: Bool) {
        useMockData = isEnabled
    }

    private func persistUseMockDataIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(useMockData, forKey: AppConstants.UserDefaultsKeys.useMockData)
    }
}
