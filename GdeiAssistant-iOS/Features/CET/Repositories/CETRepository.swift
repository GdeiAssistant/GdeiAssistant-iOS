import Foundation

@MainActor
protocol CETRepository {
    func fetchCaptchaImageBase64() async throws -> String
    func queryScore(request: CETScoreQueryRequest) async throws -> CETDashboard
}

@MainActor
final class SwitchingCETRepository: CETRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any CETRepository
    private let mockRepository: any CETRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any CETRepository,
        mockRepository: any CETRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchCaptchaImageBase64() async throws -> String {
        try await currentRepository.fetchCaptchaImageBase64()
    }

    func queryScore(request: CETScoreQueryRequest) async throws -> CETDashboard {
        try await currentRepository.queryScore(request: request)
    }

    private var currentRepository: any CETRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
