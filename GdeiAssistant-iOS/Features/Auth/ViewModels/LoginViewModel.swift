import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true
    @Published var campusCredentialConsentChecked = false
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

    var requiresCampusCredentialConsent: Bool {
        currentDataSourceMode == .remote
    }

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }

    func login() async {
        guard canSubmit else {
            errorMessage = localizedString("login.formEmpty")
            return
        }

        guard !requiresCampusCredentialConsent || campusCredentialConsentChecked else {
            errorMessage = localizedString("login.campusCredentialConsentRequired")
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let consentMetadata = requiresCampusCredentialConsent ? CampusCredentialConsentMetadata() : nil
            _ = try await authManager.login(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                consentMetadata: consentMetadata
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("login.failed")
        }
    }
}
