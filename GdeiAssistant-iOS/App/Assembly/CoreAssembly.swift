import Foundation

/// Owns repository construction and ViewModel factories for auth, home, and shared infrastructure.
@MainActor
struct CoreAssembly {
    let authRepository: any AuthRepository

    init(apiClient: APIClient, environment: AppEnvironment) {
        let remoteAuthRepository = RemoteAuthRepository(apiClient: apiClient)
        let mockAuthRepository = MockAuthRepository()
        self.authRepository = SwitchingAuthRepository(
            environment: environment,
            remoteRepository: remoteAuthRepository,
            mockRepository: mockAuthRepository
        )
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel(authManager: AuthManager) -> LoginViewModel {
        LoginViewModel(authManager: authManager)
    }

    func makeHomeViewModel(scheduleRepository: any ScheduleRepository) -> HomeViewModel {
        HomeViewModel(scheduleRepository: scheduleRepository)
    }
}
