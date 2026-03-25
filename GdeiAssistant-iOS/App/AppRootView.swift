import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var sessionState: SessionState
    @EnvironmentObject private var router: AppRouter

    @State private var showAuthAlert = false
    @State private var authAlertMessage = ""
    @State private var bootstrapAttempt = 0
    @State private var hasBootstrapTimedOut = false

    var body: some View {
        ZStack {
            DSColor.background
                .ignoresSafeArea()

            Group {
                if hasBootstrapTimedOut && sessionState.isRestoringSession {
                    startupFallbackView
                } else if sessionState.isRestoringSession {
                    DSLoadingView(text: localizedString("startup.restoringSession"))
                } else if sessionState.isLoggedIn {
                    MainTabView()
                } else {
                    LoginView(viewModel: container.makeLoginViewModel())
                }
            }
        }
        .task(id: bootstrapAttempt) {
            await startBootstrap(force: bootstrapAttempt > 0)
        }
        .onChange(of: sessionState.authErrorMessage) { _, newValue in
            guard let newValue, !newValue.isEmpty else { return }
            authAlertMessage = newValue
            showAuthAlert = true
        }
        .onChange(of: sessionState.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                router.resetAfterLogout()
            }
        }
        .environment(\.locale, Locale(identifier: preferences.selectedLocale))
        .environment(\.sizeCategory, preferences.sizeCategory)
        .alert(Text(LocalizedStringKey("startup.alert.title")), isPresented: $showAuthAlert) {
            Button(localizedString("startup.alert.dismiss")) {
                sessionState.authErrorMessage = nil
            }
        } message: {
            Text(authAlertMessage)
        }
    }

    private var startupFallbackView: some View {
        VStack(spacing: 18) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(DSColor.primary)

            VStack(spacing: 6) {
                Text(AppConstants.Brand.shortDisplayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DSColor.title)

                Text(environment.dataSourceMode == .mock
                     ? localizedString("startup.dataSource.mock")
                     : localizedString("startup.dataSource.remote"))
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            }

            DSErrorStateView(message: localizedString("startup.timeout")) {
                bootstrapAttempt += 1
            }
            .frame(maxHeight: 220)

            DSButton(
                title: localizedString("startup.goToLogin"),
                icon: "person.crop.circle.badge.exclamationmark",
                variant: .secondary
            ) {
                container.authManager.clearToken()
                sessionState.markLoggedOut(message: localizedString("startup.restoreFailed"))
            }
            .frame(maxWidth: 220)
        }
        .padding(24)
    }

    private func startBootstrap(force: Bool) async {
        hasBootstrapTimedOut = false

        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            if !Task.isCancelled && sessionState.isRestoringSession {
                hasBootstrapTimedOut = true
            }
        }

        await container.bootstrapIfNeeded(force: force)
        timeoutTask.cancel()
        hasBootstrapTimedOut = false
    }
}

#Preview {
    let container = AppContainer.preview
    return AppRootView()
        .environmentObject(container)
        .environmentObject(container.environment)
        .environmentObject(container.userPreferences)
        .environmentObject(container.sessionState)
        .environmentObject(container.router)
}
