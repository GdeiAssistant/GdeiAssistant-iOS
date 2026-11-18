import Foundation

@MainActor
final class MockProfileRepository: ProfileRepository {
    private var currentProfile = MockFactory.makeUserProfile()

    // No actor-bound cleanup; allow synchronous ARC release without the
    // iOS 26.2 MainActor isolated-deinit back-deployment path.
    nonisolated deinit {}

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
        let selectedFaculty = options.faculties.first(where: { $0.code == request.facultyCode })
        let normalizedMajorCode = request.majorCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedMajorCode = (normalizedMajorCode?.isEmpty == false && normalizedMajorCode != "unselected")
            ? normalizedMajorCode
            : nil
        let resolvedMajorLabel = resolvedMajorCode.flatMap { code in
            selectedFaculty?.majors.first(where: { $0.code == code })?.label
        } ?? ""
        let resolvedCollegeLabel = request.facultyCode == 0 ? "" : (selectedFaculty?.label ?? "")
        let resolvedGrade = request.enrollment.map(String.init) ?? ""

        currentProfile = UserProfile(
            id: currentProfile.id,
            username: currentProfile.username,
            nickname: request.nickname,
            avatarURL: currentProfile.avatarURL,
            college: resolvedCollegeLabel,
            collegeCode: request.facultyCode,
            major: resolvedMajorLabel,
            majorCode: resolvedMajorCode,
            grade: resolvedGrade,
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? "",
            locationSelection: request.location,
            hometown: request.hometown?.displayName ?? "",
            hometownSelection: request.hometown,
            ipArea: currentProfile.ipArea
        )

        return currentProfile
    }
}
