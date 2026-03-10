import Foundation

@MainActor
protocol EvaluateRepository {
    func submit(_ submission: EvaluateSubmission) async throws
}

@MainActor
final class SwitchingEvaluateRepository: EvaluateRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any EvaluateRepository
    private let mockRepository: any EvaluateRepository

    init(environment: AppEnvironment, remoteRepository: any EvaluateRepository, mockRepository: any EvaluateRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func submit(_ submission: EvaluateSubmission) async throws {
        try await currentRepository.submit(submission)
    }

    private var currentRepository: any EvaluateRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
