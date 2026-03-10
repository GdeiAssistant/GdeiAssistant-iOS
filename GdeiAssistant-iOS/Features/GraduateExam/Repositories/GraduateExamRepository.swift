import Foundation

@MainActor
protocol GraduateExamRepository {
    func queryScore(_ query: GraduateExamQuery) async throws -> GraduateExamScore
}

@MainActor
final class SwitchingGraduateExamRepository: GraduateExamRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any GraduateExamRepository
    private let mockRepository: any GraduateExamRepository

    init(environment: AppEnvironment, remoteRepository: any GraduateExamRepository, mockRepository: any GraduateExamRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func queryScore(_ query: GraduateExamQuery) async throws -> GraduateExamScore {
        try await currentRepository.queryScore(query)
    }

    private var currentRepository: any GraduateExamRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
