import Foundation

/// Owns repository construction and ViewModel factories for auth, home, and shared infrastructure.
@MainActor
struct CoreAssembly {
    private let environment: AppEnvironment
    private let remoteAuthRepository: RemoteAuthRepository
    private let mockAuthRepository: MockAuthRepository

    var authRepository: any AuthRepository {
        authRepository(for: environment.dataSourceMode)
    }

    func authRepository(for mode: DataSourceMode) -> any AuthRepository {
        mode == .mock ? mockAuthRepository : remoteAuthRepository
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteAuthRepository = RemoteAuthRepository(apiClient: apiClient)
        self.mockAuthRepository = MockAuthRepository()
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel(authManager: AuthManager) -> LoginViewModel {
        LoginViewModel(authManager: authManager)
    }

    func makeHomeViewModel(scheduleRepository: any ScheduleRepository) -> HomeViewModel {
        HomeViewModel(scheduleRepository: scheduleRepository)
    }
}
