import Foundation

/// Owns repository construction and ViewModel factories for auth, home, and shared infrastructure.
@MainActor
struct CoreAssembly {
    private let environment: AppEnvironment
    private let remoteAuthRepository: RemoteAuthRepository
    #if DEBUG
    private let mockAuthRepository: MockAuthRepository
    #endif

    var authRepository: any AuthRepository {
        authRepository(for: environment.dataSourceMode)
    }

    func authRepository(for mode: DataSourceMode) -> any AuthRepository {
        #if DEBUG
        return mode == .mock ? mockAuthRepository : remoteAuthRepository
        #else
        return remoteAuthRepository
        #endif
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteAuthRepository = RemoteAuthRepository(apiClient: apiClient)
        #if DEBUG
        self.mockAuthRepository = MockAuthRepository()
        #endif
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel(authManager: AuthManager) -> LoginViewModel {
        LoginViewModel(authManager: authManager)
    }

    func makeHomeViewModel(scheduleRepository: any ScheduleRepository) -> HomeViewModel {
        HomeViewModel(scheduleRepository: scheduleRepository)
    }
}
