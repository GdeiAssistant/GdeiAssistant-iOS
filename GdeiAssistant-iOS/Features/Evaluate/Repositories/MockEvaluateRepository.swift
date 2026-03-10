import Foundation

@MainActor
final class MockEvaluateRepository: EvaluateRepository {
    func submit(_ submission: EvaluateSubmission) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        _ = submission
    }
}
