import Foundation

@MainActor
final class RemoteProfileRepository: ProfileRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProfile() async throws -> UserProfile {
        let profileDTO: UserProfileDTO = try await apiClient.get("/user/profile", requiresAuth: true)
        return ProfileRemoteMapper.mapProfile(profileDTO)
    }

    func fetchLocationRegions() async throws -> [ProfileLocationRegion] {
        let dtos: [ProfileLocationRegionDTO] = try await apiClient.get("/profile/locations", requiresAuth: true)
        return ProfileRemoteMapper.mapLocationRegions(dtos)
    }

    func fetchProfileOptions() async throws -> ProfileOptions {
        let dto: ProfileOptionsDTO = try await apiClient.get("/profile/options", requiresAuth: true)
        return ProfileRemoteMapper.mapProfileOptions(dto)
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        let patchDTO = try ProfileRemoteMapper.makePatchDTO(from: request)
        let _: EmptyPayload = try await apiClient.post("/profile", body: patchDTO, requiresAuth: true)
        return try await fetchProfile()
    }
}
