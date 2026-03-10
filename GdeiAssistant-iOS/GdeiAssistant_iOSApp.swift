import SwiftUI

@main
struct GdeiAssistant_iOSApp: App {
    @StateObject private var container = AppContainer()

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
