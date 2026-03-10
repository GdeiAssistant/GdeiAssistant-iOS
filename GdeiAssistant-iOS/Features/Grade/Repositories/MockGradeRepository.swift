import Foundation

@MainActor
final class MockGradeRepository: GradeRepository {
    func fetchGrades(academicYear: String) async throws -> GradeReport {
        try await Task.sleep(nanoseconds: 280_000_000)
        return MockFactory.makeGradeReport(academicYear: academicYear)
    }
}
