import Foundation

@MainActor
protocol GradeRepository {
    func fetchGrades(yearIndex: Int?) async throws -> GradeReport
}

@MainActor
final class SwitchingGradeRepository: GradeRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any GradeRepository
    private let mockRepository: any GradeRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any GradeRepository,
        mockRepository: any GradeRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchGrades(yearIndex: Int?) async throws -> GradeReport {
        try await currentRepository.fetchGrades(yearIndex: yearIndex)
    }

    private var currentRepository: any GradeRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
