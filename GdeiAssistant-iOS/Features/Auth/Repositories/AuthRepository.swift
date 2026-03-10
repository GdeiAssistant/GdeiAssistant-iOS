import Foundation

@MainActor
protocol AuthRepository {
    func login(request: LoginRequest) async throws -> LoginResponse
    func logout() async throws
    func fetchProfile() async throws -> UserProfile
}

@MainActor
final class SwitchingAuthRepository: AuthRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any AuthRepository
    private let mockRepository: any AuthRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any AuthRepository,
        mockRepository: any AuthRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func login(request: LoginRequest) async throws -> LoginResponse {
        try await currentRepository.login(request: request)
    }

    func logout() async throws {
        try await currentRepository.logout()
    }

    func fetchProfile() async throws -> UserProfile {
        try await currentRepository.fetchProfile()
    }

    private var currentRepository: any AuthRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
