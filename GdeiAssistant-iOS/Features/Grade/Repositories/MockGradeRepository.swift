import Foundation

@MainActor
final class MockGradeRepository: GradeRepository {
    func fetchGrades(yearIndex: Int?) async throws -> GradeReport {
        try await Task.sleep(nanoseconds: 280_000_000)
        let index = yearIndex ?? 3
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: Date())
        let startYear = (calendar.component(.month, from: Date()) >= 8 ? year : year - 1) - (3 - index)
        let report = MockFactory.makeGradeReport(academicYear: "\(startYear)-\(startYear + 1)")
        return GradeReport(selectedYear: String(index), yearOptions: GradeRemoteMapper.yearOptions(),
                           summary: report.summary, terms: report.terms)
    }
}
