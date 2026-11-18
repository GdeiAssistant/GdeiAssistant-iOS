import Foundation

@MainActor
protocol GraduateExamRepository {
    func queryScore(_ query: GraduateExamQuery) async throws -> GraduateExamScore
}
