import Foundation

@MainActor
final class MockGraduateExamRepository: GraduateExamRepository {
    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    func queryScore(_ query: GraduateExamQuery) async throws -> GraduateExamScore {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard FormValidationSupport.hasText(query.name), FormValidationSupport.hasText(query.examNumber), FormValidationSupport.hasText(query.idNumber) else {
            throw NetworkError.server(code: 400, message: localizedString("graduateExam.formIncomplete"))
        }
        return GraduateExamScore(name: query.name, signupNumber: "K202600889", examNumber: query.examNumber, totalScore: "372", politicsScore: "68", foreignLanguageScore: "74", businessOneScore: "116", businessTwoScore: "114")
    }
}
