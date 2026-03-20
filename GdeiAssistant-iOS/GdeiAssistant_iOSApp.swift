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
        }
    }
}
