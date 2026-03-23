import Foundation

/// Owns repository construction for auth, home, and shared infrastructure.
struct CoreAssembly {
    let authRepository: any AuthRepository
    let homeRepository: any HomeRepository

    init(apiClient: APIClient, environment: AppEnvironment) {
        let remoteAuthRepository = RemoteAuthRepository(apiClient: apiClient)
        let mockAuthRepository = MockAuthRepository()
        self.authRepository = SwitchingAuthRepository(
            environment: environment,
            remoteRepository: remoteAuthRepository,
            mockRepository: mockAuthRepository
        )

        let remoteHomeRepository = RemoteHomeRepository(apiClient: apiClient)
        let mockHomeRepository = MockHomeRepository()
        self.homeRepository = SwitchingHomeRepository(
            environment: environment,
            remoteRepository: remoteHomeRepository,
            mockRepository: mockHomeRepository
        )
    }
}
