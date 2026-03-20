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
                    DSLoadingView(text: "正在恢复登录状态...")
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
        .id(preferences.selectedThemeKey)
        .alert("提示", isPresented: $showAuthAlert) {
            Button("知道了") {
                sessionState.authErrorMessage = nil
            }
        } message: {
            Text(authAlertMessage)
        }
    }

    private var startupFallbackView: some View {
        VStack(spacing: 18) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(DSColor.primary)

            VStack(spacing: 6) {
                Text(AppConstants.Brand.shortDisplayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DSColor.title)

                Text(environment.dataSourceMode == .mock ? "当前使用 mock 数据源" : "当前使用 remote 数据源")
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            }

            DSErrorStateView(message: AppConstants.Debug.bootstrapTimeoutMessage) {
                bootstrapAttempt += 1
            }
            .frame(maxHeight: 220)

            DSButton(title: "进入登录页", icon: "person.crop.circle.badge.exclamationmark", variant: .secondary) {
                container.authManager.clearToken()
                sessionState.markLoggedOut(message: "启动恢复失败，请重新登录")
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
