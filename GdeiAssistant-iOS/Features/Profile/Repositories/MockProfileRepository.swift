import Foundation

@MainActor
final class MockProfileRepository: ProfileRepository {
    private var currentProfile = MockFactory.makeUserProfile()

    func fetchProfile() async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 300_000_000)
        return currentProfile
    }

    func fetchLocationRegions() async throws -> [ProfileLocationRegion] {
        try await Task.sleep(nanoseconds: 120_000_000)
        return ProfileLocationCatalog.regions
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 280_000_000)

        currentProfile = UserProfile(
            id: currentProfile.id,
            username: currentProfile.username,
            nickname: request.nickname,
            avatarURL: currentProfile.avatarURL,
            college: request.college,
            major: request.major,
            grade: request.grade,
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? currentProfile.location,
            hometown: request.hometown?.displayName ?? currentProfile.hometown,
            ipArea: currentProfile.ipArea
        )

        return currentProfile
    }
}
