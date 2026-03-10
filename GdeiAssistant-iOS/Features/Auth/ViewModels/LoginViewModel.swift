import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    var currentDataSourceMode: DataSourceMode {
        authManager.currentDataSourceMode
    }

    var shouldShowMockHint: Bool {
        currentDataSourceMode == .mock
    }

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }

    func login() async {
        guard canSubmit else {
            errorMessage = "请输入账号和密码"
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            _ = try await authManager.login(username: username, password: password)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "登录失败，请稍后重试"
        }
    }
}
