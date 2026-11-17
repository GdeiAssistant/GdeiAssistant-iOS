import Foundation

@MainActor
protocol ProfileRepository {
    func fetchProfile() async throws -> UserProfile
    func fetchLocationRegions() async throws -> [ProfileLocationRegion]
    func fetchProfileOptions() async throws -> ProfileOptions
    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile
}
