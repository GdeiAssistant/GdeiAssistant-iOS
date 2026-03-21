import Foundation
import Combine

@MainActor
final class UserPreferences: ObservableObject {
    @Published var useMockData: Bool {
        didSet { persistUseMockDataIfNeeded() }
    }
    @Published var networkEnvironment: NetworkEnvironment {
        didSet { persistNetworkEnvironmentIfNeeded() }
    }
    @Published var selectedThemeKey: String {
        didSet { persistThemeIfNeeded() }
    }
    @Published var selectedLocale: String {
        didSet { persistLocaleIfNeeded() }
    }

    private let defaults: UserDefaults
    private var hasInitialized = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedUseMockData = defaults.object(forKey: AppConstants.UserDefaultsKeys.useMockData) as? Bool {
            self.useMockData = storedUseMockData
        } else {
            self.useMockData = false
        }
        if
            let storedEnvironment = defaults.string(forKey: AppConstants.UserDefaultsKeys.networkEnvironment),
            let resolvedEnvironment = NetworkEnvironment(rawValue: storedEnvironment)
        {
            self.networkEnvironment = resolvedEnvironment
        } else {
            self.networkEnvironment = .prod
        }
        if let storedTheme = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedTheme) {
            self.selectedThemeKey = storedTheme
        } else {
            self.selectedThemeKey = DSTheme.campusGreen.rawValue
        }
        if let storedLocale = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedLocale) {
            self.selectedLocale = storedLocale
        } else {
            self.selectedLocale = Self.detectSystemLocale()
        }
        hasInitialized = true
    }

    var currentTheme: DSTheme {
        DSTheme(rawValue: selectedThemeKey) ?? .campusGreen
    }

    var currentDataSourceMode: DataSourceMode {
        useMockData ? .mock : .remote
    }

    var currentNetworkEnvironment: NetworkEnvironment {
        networkEnvironment
    }

    func setUseMockData(_ isEnabled: Bool) {
        useMockData = isEnabled
    }

    func setNetworkEnvironment(_ environment: NetworkEnvironment) {
        networkEnvironment = environment
    }

    private func persistUseMockDataIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(useMockData, forKey: AppConstants.UserDefaultsKeys.useMockData)
    }

    private func persistNetworkEnvironmentIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(networkEnvironment.rawValue, forKey: AppConstants.UserDefaultsKeys.networkEnvironment)
    }

    private func persistThemeIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(selectedThemeKey, forKey: AppConstants.UserDefaultsKeys.selectedTheme)
    }

    private func persistLocaleIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(selectedLocale, forKey: AppConstants.UserDefaultsKeys.selectedLocale)
    }

    private static func detectSystemLocale() -> String {
        let lang = Locale.current.language.languageCode?.identifier ?? "zh"
        let region = Locale.current.region?.identifier ?? ""
        switch "\(lang)-\(region)" {
        case "zh-HK": return "zh-HK"
        case "zh-TW": return "zh-TW"
        default: break
        }
        switch lang {
        case "zh": return "zh-CN"
        case "ja": return "ja"
        case "ko": return "ko"
        case "en": return "en"
        default: return "zh-CN"
        }
    }
}
