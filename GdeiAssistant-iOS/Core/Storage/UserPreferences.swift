import Foundation
import Combine
import SwiftUI

@MainActor
final class UserPreferences: ObservableObject {
    enum ThemeMode: String, CaseIterable {
        case system, light, dark
    }

    @Published var useMockData: Bool {
        didSet { persistUseMockDataIfNeeded() }
    }
    @Published var networkEnvironment: NetworkEnvironment {
        didSet { persistNetworkEnvironmentIfNeeded() }
    }
    @Published var selectedLocale: String {
        didSet {
            let normalizedLocale = AppLanguage.normalizedIdentifier(from: selectedLocale)
            if selectedLocale != normalizedLocale {
                selectedLocale = normalizedLocale
                return
            }
            persistLocaleIfNeeded()
        }
    }
    @Published var selectedTheme: ThemeMode = .system {
        didSet { persistThemeIfNeeded() }
    }
    @Published var fontScaleStep: Int = 1 {
        didSet { persistFontScaleStepIfNeeded() }
    }

    static let fontScaleValues: [CGFloat] = [0.85, 1.0, 1.15, 1.3]

    var fontScale: CGFloat { Self.fontScaleValues[fontScaleStep.clamped(to: 0...3)] }

    var sizeCategory: ContentSizeCategory {
        switch fontScaleStep.clamped(to: 0...3) {
        case 0: return .small
        case 1: return .medium
        case 2: return .large
        case 3: return .extraExtraLarge
        default: return .medium
        }
    }

    private let defaults: UserDefaults
    private var hasInitialized = false

    private static var buildDefaultNetworkEnvironment: NetworkEnvironment {
        NetworkEnvironment(rawValue: AppConstants.API.defaultNetworkEnvironment) ?? .prod
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if AppConstants.API.allowsRuntimeDebugOptions,
           let storedUseMockData = defaults.object(forKey: AppConstants.UserDefaultsKeys.useMockData) as? Bool {
            self.useMockData = storedUseMockData
        } else {
            self.useMockData = false
        }
        if
            AppConstants.API.allowsRuntimeDebugOptions,
            let storedEnvironment = defaults.string(forKey: AppConstants.UserDefaultsKeys.networkEnvironment),
            let resolvedEnvironment = NetworkEnvironment(rawValue: storedEnvironment)
        {
            self.networkEnvironment = resolvedEnvironment
        } else {
            self.networkEnvironment = Self.buildDefaultNetworkEnvironment
        }
        if let storedLocale = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedLocale) {
            self.selectedLocale = AppLanguage.normalizedIdentifier(from: storedLocale)
        } else {
            self.selectedLocale = Self.detectSystemLocale()
        }
        if let themeRaw = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedTheme),
           let theme = ThemeMode(rawValue: themeRaw) {
            self.selectedTheme = theme
        }
        if defaults.object(forKey: AppConstants.UserDefaultsKeys.fontScaleStep) != nil {
            self.fontScaleStep = defaults.integer(forKey: AppConstants.UserDefaultsKeys.fontScaleStep).clamped(to: 0...3)
        }
        hasInitialized = true
    }

    /// Reads the persisted locale directly from UserDefaults so that
    /// non-SwiftUI code (computed properties, utility functions) can resolve
    /// the correct localization bundle without holding an instance reference.
    nonisolated static var currentLocale: String {
        AppLanguage.currentIdentifier()
    }

    var currentDataSourceMode: DataSourceMode {
        AppConstants.API.allowsRuntimeDebugOptions && useMockData ? .mock : .remote
    }

    var currentNetworkEnvironment: NetworkEnvironment {
        AppConstants.API.allowsRuntimeDebugOptions ? networkEnvironment : Self.buildDefaultNetworkEnvironment
    }

    func setUseMockData(_ isEnabled: Bool) {
        useMockData = AppConstants.API.allowsRuntimeDebugOptions ? isEnabled : false
    }

    func setNetworkEnvironment(_ environment: NetworkEnvironment) {
        networkEnvironment = AppConstants.API.allowsRuntimeDebugOptions ? environment : Self.buildDefaultNetworkEnvironment
    }

    private func persistUseMockDataIfNeeded() {
        guard hasInitialized else { return }
        guard AppConstants.API.allowsRuntimeDebugOptions else {
            defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.useMockData)
            return
        }
        defaults.set(useMockData, forKey: AppConstants.UserDefaultsKeys.useMockData)
    }

    private func persistNetworkEnvironmentIfNeeded() {
        guard hasInitialized else { return }
        guard AppConstants.API.allowsRuntimeDebugOptions else {
            defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.networkEnvironment)
            return
        }
        defaults.set(networkEnvironment.rawValue, forKey: AppConstants.UserDefaultsKeys.networkEnvironment)
    }

    private func persistLocaleIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(
            AppLanguage.normalizedIdentifier(from: selectedLocale),
            forKey: AppConstants.UserDefaultsKeys.selectedLocale
        )
    }

    private func persistThemeIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(selectedTheme.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedTheme)
    }

    private func persistFontScaleStepIfNeeded() {
        guard hasInitialized else { return }
        defaults.set(fontScaleStep, forKey: AppConstants.UserDefaultsKeys.fontScaleStep)
    }

    private nonisolated static func detectSystemLocale() -> String {
        AppLanguage.detectSystemLanguage()
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
