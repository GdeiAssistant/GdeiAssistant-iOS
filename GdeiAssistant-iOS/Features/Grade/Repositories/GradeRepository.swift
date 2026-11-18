import Foundation

@MainActor
protocol GradeRepository {
    func fetchGrades(yearIndex: Int?) async throws -> GradeReport
}
