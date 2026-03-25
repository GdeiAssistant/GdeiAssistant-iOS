import Foundation
import Combine

enum AuthManagerError: LocalizedError {
    case repositoryNotConfigured

    var errorDescription: String? {
        switch self {
        case .repositoryNotConfigured:
            return localizedString("auth.repositoryNotConfigured")
        }
    }
}

@MainActor
final class AuthManager: ObservableObject {
    private let tokenStorage: TokenStorage
    private let sessionState: SessionState

    private var authRepository: (any AuthRepository)?
    private var dataSourceModeProvider: (() -> DataSourceMode)?
    private var cachedToken: String?

    init(tokenStorage: TokenStorage, sessionState: SessionState) {
        self.tokenStorage = tokenStorage
        self.sessionState = sessionState
    }

    func configure(
        repository: any AuthRepository,
        dataSourceModeProvider: @escaping () -> DataSourceMode
    ) {
        authRepository = repository
        self.dataSourceModeProvider = dataSourceModeProvider
    }

    var currentDataSourceMode: DataSourceMode {
        dataSourceModeProvider?() ?? .remote
    }

    func currentToken() -> String? {
        if let cachedToken {
            return cachedToken
        }

        guard let token = try? tokenStorage.loadToken() else {
            return nil
        }

        cachedToken = token
        return token
    }

    func restoreSession() async {
        sessionState.beginRestoringSession()
        defer { sessionState.isRestoringSession = false }

        guard let token = currentToken(), !token.isEmpty else {
            sessionState.markLoggedOut()
            return
        }

        guard let repository = authRepository else {
            sessionState.markLoggedOut()
            return
        }

        do {
            let profile = try await repository.fetchProfile()
            sessionState.markLoggedIn(user: profile)
        } catch {
            if case NetworkError.unauthorized = error {
                handleUnauthorized()
            } else {
                sessionState.markLoggedOut(
                    message: (error as? LocalizedError)?.errorDescription ?? localizedString("auth.restoreFailed")
                )
            }
        }
    }

    @discardableResult
    func login(username: String, password: String) async throws -> UserProfile {
        guard let repository = authRepository else {
            throw AuthManagerError.repositoryNotConfigured
        }

        let request = LoginRequest(username: username, password: password)
        let response = try await repository.login(request: request)
        try tokenStorage.saveToken(response.token)
        cachedToken = response.token

        do {
            let profile = try await repository.fetchProfile()
            sessionState.markLoggedIn(user: profile)
            return profile
        } catch {
            clearToken()
            throw error
        }
    }

    func logout() async {
        if let repository = authRepository {
            try? await repository.logout()
        }
        clearToken()
        sessionState.markLoggedOut()
    }

    func clearToken() {
        try? tokenStorage.deleteToken()
        cachedToken = nil
    }

    func handleUnauthorized() {
        clearToken()
        sessionState.markLoggedOut(message: localizedString("auth.sessionExpired"))
    }
}
