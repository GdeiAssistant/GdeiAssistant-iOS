import Foundation

@MainActor
final class MockAuthRepository: AuthRepository {
    private let validUsername = "gdeiassistant"
    private let validPassword = "gdeiassistant"

    func login(request: LoginRequest) async throws -> LoginResponse {
        try await Task.sleep(nanoseconds: 500_000_000)

        let username = request.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = request.password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard username == validUsername, password == validPassword else {
            throw NetworkError.server(code: 40001, message: "账号或密码错误，请检查后重试")
        }

        return MockFactory.makeLoginResponse(username: username)
    }

    func logout() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    func fetchProfile() async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 350_000_000)
        return MockFactory.makeUserProfile()
    }
}
