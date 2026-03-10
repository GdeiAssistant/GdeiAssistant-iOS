import Foundation

@MainActor
final class RemoteAuthRepository: AuthRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func login(request: LoginRequest) async throws -> LoginResponse {
        let requestDTO = AuthRemoteMapper.mapLoginRequest(request)
        let responseDTO: LoginResponseDTO = try await apiClient.post("/auth/login", body: requestDTO, requiresAuth: false)
        return AuthRemoteMapper.mapLoginResponse(responseDTO)
    }

    func logout() async throws {
        let _: EmptyPayload = try await apiClient.post("/auth/logout", requiresAuth: true)
    }

    func fetchProfile() async throws -> UserProfile {
        let profileDTO: UserProfileDTO = try await apiClient.get("/user/profile", requiresAuth: true)
        return ProfileRemoteMapper.mapProfile(profileDTO)
    }
}
