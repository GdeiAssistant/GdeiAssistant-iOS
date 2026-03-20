import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class AuthManagerTests: XCTestCase {
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
        XCTAssertEqual(sessionState.authErrorMessage, "登录状态已过期，请重新登录")
        XCTAssertFalse(sessionState.isRestoringSession)
    }
}
