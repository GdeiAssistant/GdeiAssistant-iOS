import SwiftUI

private enum AppRuntime {
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["GDEIASSISTANT_RUNNING_TESTS"] == "1"
            || environment["XCTestConfigurationFilePath"] != nil
    }
}

@main
struct GdeiAssistant_iOSApp: App {
    @StateObject private var container: AppContainer

    init() {
        _container = StateObject(
            wrappedValue: AppRuntime.isRunningTests ? AppContainer.testing : AppContainer()
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(container)
                .environmentObject(container.environment)
                .environmentObject(container.userPreferences)
                .environmentObject(container.sessionState)
                .environmentObject(container.router)
                .environment(\.locale, Locale(identifier: container.userPreferences.selectedLocale))
                .environment(\.sizeCategory, container.userPreferences.sizeCategory)
                .preferredColorScheme(colorSchemeFor(container.userPreferences.selectedTheme))
        }
    }

    private func colorSchemeFor(_ theme: UserPreferences.ThemeMode) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
