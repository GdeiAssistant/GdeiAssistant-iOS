import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class AuthManagerTests: XCTestCase {
    func testLoginThrowsWhenRepositoryIsNotConfigured() async {
        let tokenStorage = TrackingTokenStorage()
        let sessionState = SessionState()
        let manager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)

        do {
            _ = try await manager.login(username: "student", password: "secret")
            XCTFail("Expected missing repository to throw")
        } catch {
            XCTAssertEqual(
                (error as? AuthManagerError)?.errorDescription,
                AuthManagerError.repositoryNotConfigured.errorDescription
            )
        }
    }

    func testLoginPersistsTokenAndMarksSessionLoggedIn() async throws {
        let tokenStorage = TrackingTokenStorage()
        let sessionState = SessionState()
        let repository = AuthRepositorySpy()
        let manager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)
        manager.configure(repository: repository, dataSourceModeProvider: { .remote })

        let profile = try await manager.login(username: "student", password: "secret")

        XCTAssertEqual(profile, repository.profile)
        XCTAssertEqual(tokenStorage.token, repository.loginResponse.token)
        XCTAssertEqual(repository.loginRequests.count, 1)
        XCTAssertEqual(repository.loginRequests[0].username, "student")
        XCTAssertEqual(repository.loginRequests[0].password, "secret")
        XCTAssertTrue(sessionState.isLoggedIn)
        XCTAssertEqual(sessionState.currentUser, repository.profile)
    }

    func testLoginRollsBackPersistedTokenWhenProfileFetchFails() async {
        let tokenStorage = TrackingTokenStorage()
        let sessionState = SessionState()
        let repository = AuthRepositorySpy()
        repository.profileError = NetworkError.transport(URLError(.timedOut))

        let manager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)
        manager.configure(repository: repository, dataSourceModeProvider: { .remote })

        do {
            _ = try await manager.login(username: "student", password: "secret")
            XCTFail("Expected login to throw when profile loading fails")
        } catch {
            XCTAssertNil(tokenStorage.token)
            XCTAssertEqual(tokenStorage.deleteCallCount, 1)
            XCTAssertFalse(sessionState.isLoggedIn)
            XCTAssertNil(sessionState.currentUser)
        }
    }

    func testRestoreSessionClearsTokenOnUnauthorized() async throws {
        let tokenStorage = TrackingTokenStorage()
        try tokenStorage.saveToken("expired-token")
        let sessionState = SessionState()
        let repository = AuthRepositorySpy()
        repository.profileError = NetworkError.unauthorized

        let manager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)
        manager.configure(repository: repository, dataSourceModeProvider: { .remote })

        await manager.restoreSession()

        XCTAssertNil(tokenStorage.token)
        XCTAssertFalse(sessionState.isLoggedIn)
        XCTAssertEqual(sessionState.authErrorMessage, localizedString("auth.sessionExpired"))
        XCTAssertFalse(sessionState.isRestoringSession)
    }

    func testCurrentTokenReturnsNilWhenTokenStorageLoadFails() {
        let tokenStorage = TrackingTokenStorage()
        tokenStorage.loadError = NSError(domain: "AuthManagerTests", code: 1)
        let sessionState = SessionState()
        let manager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)
        TestLifetimeRetainer.retain(manager)

        XCTAssertNil(manager.currentToken())
    }

    func testLogoutClearsLocalSessionEvenWhenRemoteLogoutFails() async throws {
        let tokenStorage = TrackingTokenStorage()
        try tokenStorage.saveToken("live-token")
        let sessionState = SessionState()
        let repository = AuthRepositorySpy()
        repository.logoutError = NetworkError.transport(URLError(.cannotConnectToHost))
        let manager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)
        manager.configure(repository: repository, dataSourceModeProvider: { .remote })

        await manager.logout()

        XCTAssertEqual(repository.logoutCallCount, 1)
        XCTAssertNil(tokenStorage.token)
        XCTAssertEqual(tokenStorage.deleteCallCount, 1)
        XCTAssertFalse(sessionState.isLoggedIn)
        XCTAssertNil(sessionState.currentUser)
    }
}

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testCampusPasswordLoginRequiresCredentialConsentInRemoteMode() async {
        let repository = AuthRepositorySpy()
        let viewModel = makeViewModel(repository: repository, dataSourceMode: .remote)
        viewModel.username = "student"
        viewModel.password = "secret"

        await viewModel.login()

        XCTAssertTrue(repository.loginRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, localizedString("login.campusCredentialConsentRequired"))
    }

    func testCampusPasswordLoginSendsConsentMetadataWhenChecked() async {
        let repository = AuthRepositorySpy()
        let viewModel = makeViewModel(repository: repository, dataSourceMode: .remote)
        viewModel.username = " student "
        viewModel.password = "secret"
        viewModel.campusCredentialConsentChecked = true

        await viewModel.login()

        XCTAssertEqual(repository.loginRequests.count, 1)
        XCTAssertEqual(repository.loginRequests[0].username, "student")
        XCTAssertEqual(repository.loginRequests[0].password, "secret")
        XCTAssertEqual(repository.loginRequests[0].campusCredentialConsent, true)
        XCTAssertEqual(repository.loginRequests[0].consentScene, CampusCredentialDefaults.loginScene)
        XCTAssertEqual(repository.loginRequests[0].policyDate, CampusCredentialDefaults.policyDate)
        XCTAssertEqual(repository.loginRequests[0].effectiveDate, CampusCredentialDefaults.effectiveDate)
    }

    func testMockModeBypassesCampusCredentialConsentGate() async {
        let repository = AuthRepositorySpy()
        let viewModel = makeViewModel(repository: repository, dataSourceMode: .mock)
        viewModel.username = "gdeiassistant"
        viewModel.password = "gdeiassistant"

        await viewModel.login()

        XCTAssertEqual(repository.loginRequests.count, 1)
        XCTAssertNil(repository.loginRequests[0].campusCredentialConsent)
        XCTAssertNil(repository.loginRequests[0].consentScene)
    }

    private func makeViewModel(
        repository: AuthRepositorySpy,
        dataSourceMode: DataSourceMode
    ) -> LoginViewModel {
        let manager = AuthManager(tokenStorage: TrackingTokenStorage(), sessionState: SessionState())
        manager.configure(repository: repository, dataSourceModeProvider: { dataSourceMode })
        let viewModel = LoginViewModel(authManager: manager)
        TestLifetimeRetainer.retain(viewModel)
        TestLifetimeRetainer.retain(manager)
        return viewModel
    }
}
