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

    func fetchProfileOptions() async throws -> ProfileOptions {
        try await Task.sleep(nanoseconds: 80_000_000)
        return ProfileFormSupport.defaultOptions
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 280_000_000)

        let options = ProfileFormSupport.defaultOptions
        let normalizedCollege = request.college.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMajor = request.major.trimmingCharacters(in: .whitespacesAndNewlines)
        let collegeCode = options.facultyCode(for: normalizedCollege) ?? currentProfile.collegeCode
        let majorCode = options.majorCode(for: normalizedCollege, majorLabel: normalizedMajor) ?? currentProfile.majorCode

        currentProfile = UserProfile(
            id: currentProfile.id,
            username: currentProfile.username,
            nickname: request.nickname,
            avatarURL: currentProfile.avatarURL,
            college: request.college,
            collegeCode: collegeCode,
            major: request.major,
            majorCode: majorCode,
            grade: request.grade,
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? currentProfile.location,
            locationSelection: request.location ?? currentProfile.locationSelection,
            hometown: request.hometown?.displayName ?? currentProfile.hometown,
            hometownSelection: request.hometown ?? currentProfile.hometownSelection,
            ipArea: currentProfile.ipArea
        )

        return currentProfile
    }
}
