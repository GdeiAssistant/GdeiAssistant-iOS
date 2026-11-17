import Foundation

@MainActor
protocol AuthRepository {
    func login(request: LoginRequest) async throws -> LoginResponse
    func logout() async throws
    func fetchProfile() async throws -> UserProfile
}
