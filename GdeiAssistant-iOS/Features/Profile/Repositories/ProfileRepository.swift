import Foundation

@MainActor
protocol ProfileRepository {
    func fetchProfile() async throws -> UserProfile
    func fetchLocationRegions() async throws -> [ProfileLocationRegion]
    func fetchProfileOptions() async throws -> ProfileOptions
    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile
}

@MainActor
final class SwitchingProfileRepository: ProfileRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any ProfileRepository
    private let mockRepository: any ProfileRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any ProfileRepository,
        mockRepository: any ProfileRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchProfile() async throws -> UserProfile {
        try await currentRepository.fetchProfile()
    }

    func fetchLocationRegions() async throws -> [ProfileLocationRegion] {
        try await currentRepository.fetchLocationRegions()
    }

    func fetchProfileOptions() async throws -> ProfileOptions {
        try await currentRepository.fetchProfileOptions()
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        try await currentRepository.updateProfile(request: request)
    }

    private var currentRepository: any ProfileRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
