import Foundation

@MainActor
protocol HomeRepository {
    func fetchDashboard() async throws -> HomeDashboard
}

@MainActor
final class SwitchingHomeRepository: HomeRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any HomeRepository
    private let mockRepository: any HomeRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any HomeRepository,
        mockRepository: any HomeRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchDashboard() async throws -> HomeDashboard {
        try await currentRepository.fetchDashboard()
    }

    private var currentRepository: any HomeRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
