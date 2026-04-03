import Foundation
@testable import GdeiAssistant_iOS

final class TrackingTokenStorage: TokenStorage {
    private(set) var token: String?
    private(set) var savedTokens: [String] = []
    private(set) var deleteCallCount = 0
    var saveError: Error?
    var loadError: Error?
    var deleteError: Error?

    func saveToken(_ token: String) throws {
        if let saveError {
            throw saveError
        }
        self.token = token
        savedTokens.append(token)
    }

    func loadToken() throws -> String? {
        if let loadError {
            throw loadError
        }
        return token
    }

    func deleteToken() throws {
        if let deleteError {
            throw deleteError
        }
        deleteCallCount += 1
        token = nil
    }
}

@MainActor
final class AuthRepositorySpy: AuthRepository {
    var loginResponse = LoginResponse(token: "token-123")
    var loginError: Error?
    var profile = UserProfile(
        id: "1",
        username: "student",
        nickname: "Student",
        avatarURL: "",
        college: "计算机科学系",
        major: "软件工程",
        grade: "2023",
        bio: "bio"
    )
    var profileError: Error?
    var logoutError: Error?

    private(set) var loginRequests: [LoginRequest] = []
    private(set) var logoutCallCount = 0
    private(set) var fetchProfileCallCount = 0

    func login(request: LoginRequest) async throws -> LoginResponse {
        loginRequests.append(request)
        if let loginError {
            throw loginError
        }
        return loginResponse
    }

    func logout() async throws {
        logoutCallCount += 1
        if let logoutError {
            throw logoutError
        }
    }

    func fetchProfile() async throws -> UserProfile {
        fetchProfileCallCount += 1
        if let profileError {
            throw profileError
        }
        return profile
    }
}
