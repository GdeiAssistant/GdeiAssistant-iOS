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
        let dtos: [ProfileLocationRegionDTO] = try await apiClient.get("/locationList", requiresAuth: true)
        return ProfileRemoteMapper.mapLocationRegions(dtos)
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        let updatePlan = try ProfileRemoteMapper.makeUpdatePlan(from: request)

        let _: EmptyPayload = try await apiClient.post("/profile/nickname", body: updatePlan.nickname, requiresAuth: true)
        let _: EmptyPayload = try await apiClient.post("/profile/faculty", body: updatePlan.faculty, requiresAuth: true)

        if let major = updatePlan.major {
            let _: EmptyPayload = try await apiClient.post("/profile/major", body: major, requiresAuth: true)
        }

        let _: EmptyPayload = try await apiClient.post("/profile/enrollment", body: updatePlan.enrollment, requiresAuth: true)
        let _: EmptyPayload = try await apiClient.post("/introduction", body: updatePlan.introduction, requiresAuth: true)

        if let birthday = updatePlan.birthday {
            let _: EmptyPayload = try await apiClient.post("/profile/birthday", body: birthday, requiresAuth: true)
        }

        if let location = updatePlan.location {
            let _: EmptyPayload = try await apiClient.post("/profile/location", body: location, requiresAuth: true)
        }

        if let hometown = updatePlan.hometown {
            let _: EmptyPayload = try await apiClient.post("/profile/hometown", body: hometown, requiresAuth: true)
        }

        return try await fetchProfile()
    }
}
